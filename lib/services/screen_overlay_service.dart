// lib/services/screen_overlay_service.dart
// خدمة عرض التحديد فوق الشاشة مع إخفاء النافذة الرئيسية

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../models/screenshot_config.dart';

class ScreenOverlayService {
  static final ScreenOverlayService _instance = ScreenOverlayService._internal();
  factory ScreenOverlayService() => _instance;
  ScreenOverlayService._internal();

  bool _isOverlayActive = false;
  Completer<ScreenshotConfig?>? _selectionCompleter;
  OverlayEntry? _overlayEntry;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// تهيئة الخدمة مع navigator key
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// بدء عملية تحديد المنطقة مع إخفاء النافذة
  Future<ScreenshotConfig?> startAreaSelection() async {
    if (_isOverlayActive) return null;
    
    _isOverlayActive = true;
    _selectionCompleter = Completer<ScreenshotConfig?>();
    
    try {
      // 1. التقاط صورة الشاشة الحالية للتجميد
      final frozenScreenshot = await _captureCurrentScreen();
      
      // 2. إخفاء النافذة الرئيسية
      await _hideMainWindow();
      
      // 3. إنشاء overlay فوق الشاشة الكاملة
      await _createFullScreenOverlay(frozenScreenshot);
      
      // 4. انتظار اختيار المستخدم
      final result = await _selectionCompleter!.future;
      
      return result;
      
    } catch (e) {
      debugPrint('خطأ في تحديد المنطقة: $e');
      return null;
    } finally {
      await _cleanup();
    }
  }

  /// التقاط صورة الشاشة الحالية للتجميد
  Future<Uint8List?> _captureCurrentScreen() async {
    try {
      // استخدام imagemagick لالتقاط الشاشة الكاملة
      final result = await Process.run('import', [
        '-window', 'root',
        '-silent',
        'png:-'
      ]);
      
      if (result.exitCode == 0) {
        return Uint8List.fromList(result.stdout);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في التقاط الشاشة: $e');
      return null;
    }
  }

  /// إخفاء النافذة الرئيسية
  Future<void> _hideMainWindow() async {
    try {
      await windowManager.hide();
      // انتظار قصير للتأكد من إخفاء النافذة
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('خطأ في إخفاء النافذة: $e');
    }
  }

  /// إنشاء overlay فوق الشاشة الكاملة
  Future<void> _createFullScreenOverlay(Uint8List? frozenScreen) async {
    if (_navigatorKey?.currentContext == null) return;
    
    // إنشاء overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) => FullScreenSelector(
        frozenScreenshot: frozenScreen,
        onAreaSelected: _onAreaSelected,
        onCancel: _onCancel,
      ),
    );
    
    // إدراج overlay
    final overlay = Overlay.of(_navigatorKey!.currentContext!);
    overlay.insert(_overlayEntry!);
    
    // تركيز الكيبورد على overlay
    await Future.delayed(const Duration(milliseconds: 100));
    _focusOverlay();
  }

  /// تركيز overlay للتحكم بالكيبورد
  void _focusOverlay() {
    try {
      final context = _navigatorKey?.currentContext;
      if (context != null) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    } catch (e) {
      debugPrint('خطأ في تركيز overlay: $e');
    }
  }

  /// معالجة اختيار المنطقة
  void _onAreaSelected(Rect selectedArea) {
    final config = ScreenshotConfig(
      x: selectedArea.left.round(),
      y: selectedArea.top.round(),
      width: selectedArea.width.round(),
      height: selectedArea.height.round(),
      outputPath: '/tmp/screenshots',
    );
    
    _selectionCompleter?.complete(config);
  }

  /// معالجة إلغاء التحديد
  void _onCancel() {
    _selectionCompleter?.complete(null);
  }

  /// تنظيف وإعادة عرض النافذة
  Future<void> _cleanup() async {
    _isOverlayActive = false;
    
    // إزالة overlay
    _overlayEntry?.remove();
    _overlayEntry = null;
    
    // إعادة عرض النافذة الرئيسية
    await _showMainWindow();
  }

  /// إعادة عرض النافذة الرئيسية
  Future<void> _showMainWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('خطأ في إعادة عرض النافذة: $e');
    }
  }
}

/// ويدجت تحديد المنطقة فوق الشاشة الكاملة
class FullScreenSelector extends StatefulWidget {
  final Uint8List? frozenScreenshot;
  final Function(Rect) onAreaSelected;
  final VoidCallback onCancel;

  const FullScreenSelector({
    Key? key,
    this.frozenScreenshot,
    required this.onAreaSelected,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<FullScreenSelector> createState() => _FullScreenSelectorState();
}

class _FullScreenSelectorState extends State<FullScreenSelector> {
  Offset? _startPoint;
  Offset? _currentPoint;
  bool _isDragging = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // الشاشة المجمدة كخلفية
                if (widget.frozenScreenshot != null)
                  Positioned.fill(
                    child: Image.memory(
                      widget.frozenScreenshot!,
                      fit: BoxFit.cover,
                    ),
                  ),
                
                // طبقة التحديد
                Positioned.fill(
                  child: CustomPaint(
                    painter: SelectionPainter(
                      startPoint: _startPoint,
                      currentPoint: _currentPoint,
                      isDragging: _isDragging,
                    ),
                  ),
                ),
                
                // تعليمات الاستخدام
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'اسحب لتحديد المنطقة • اضغط Enter للتأكيد • اضغط Escape للإلغاء',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                
                // معلومات المنطقة المحددة
                if (_startPoint != null && _currentPoint != null)
                  _buildSelectionInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// معالجة أحداث الكيبورد
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.escape:
          widget.onCancel();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.enter:
          _confirmSelection();
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// بداية التحديد
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _startPoint = details.globalPosition;
      _currentPoint = details.globalPosition;
      _isDragging = true;
    });
    HapticFeedback.selectionClick();
  }

  /// تحديث التحديد
  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoint = details.globalPosition;
    });
  }

  /// انتهاء التحديد
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    HapticFeedback.lightImpact();
  }

  /// تأكيد التحديد
  void _confirmSelection() {
    if (_startPoint != null && _currentPoint != null) {
      final rect = Rect.fromPoints(_startPoint!, _currentPoint!);
      widget.onAreaSelected(rect);
    }
  }

  /// بناء معلومات المنطقة المحددة
  Widget _buildSelectionInfo() {
    final rect = Rect.fromPoints(_startPoint!, _currentPoint!);
    final width = rect.width.abs().round();
    final height = rect.height.abs().round();
    
    return Positioned(
      left: rect.left + 10,
      top: rect.top - 35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$width × $height',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// رسام طبقة التحديد
class SelectionPainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? currentPoint;
  final bool isDragging;

  SelectionPainter({
    this.startPoint,
    this.currentPoint,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // طبقة التعتيم
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
    );
    
    // المنطقة المحددة
    if (startPoint != null && currentPoint != null) {
      final selectionRect = Rect.fromPoints(startPoint!, currentPoint!);
      
      // إزالة التعتيم من المنطقة المحددة
      final clearPaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(selectionRect, clearPaint);
      
      // رسم حدود المنطقة المحددة
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawRect(selectionRect, borderPaint);
      
      // رسم نقاط الزوايا
      _drawCornerPoints(canvas, selectionRect);
      
      // رسم خطوط التوجيه
      if (isDragging) {
        _drawGuideLines(canvas, size, selectionRect);
      }
    }
  }

  /// رسم نقاط الزوايا
  void _drawCornerPoints(Canvas canvas, Rect rect) {
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    const cornerSize = 8.0;
    
    // الزوايا الأربع
    final corners = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];
    
    for (final corner in corners) {
      canvas.drawRect(
        Rect.fromCenter(
          center: corner,
          width: cornerSize,
          height: cornerSize,
        ),
        cornerPaint,
      );
    }
  }

  /// رسم خطوط التوجيه
  void _drawGuideLines(Canvas canvas, Size size, Rect rect) {
    final guidePaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // خطوط عمودية
    canvas.drawLine(
      Offset(rect.left, 0),
      Offset(rect.left, size.height),
      guidePaint,
    );
    canvas.drawLine(
      Offset(rect.right, 0),
      Offset(rect.right, size.height),
      guidePaint,
    );
    
    // خطوط أفقية
    canvas.drawLine(
      Offset(0, rect.top),
      Offset(size.width, rect.top),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, rect.bottom),
      Offset(size.width, rect.bottom),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}