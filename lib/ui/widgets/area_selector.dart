// lib/ui/widgets/area_selector.dart
// محدد المنطقة - يسمح بتحديد منطقة السكرين شوت بصرياً

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../models/screenshot_config.dart';
import '../../utils/constants.dart';

class AreaSelector extends StatefulWidget {
  final ScreenshotConfig config;
  final Function(int x, int y, int width, int height) onAreaSelected;

  const AreaSelector({
    super.key,
    required this.config,
    required this.onAreaSelected,
  });

  @override
  State<AreaSelector> createState() => _AreaSelectorState();
}

class _AreaSelectorState extends State<AreaSelector> 
    with SingleTickerProviderStateMixin {
  bool _isSelecting = false;
  bool _showGrid = true;
  bool _snapToGrid = false;
  Offset? _startPoint;
  Offset? _endPoint;
  Rect? _selectedRect;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  // أنماط التحديد المختلفة
  SelectionMode _selectionMode = SelectionMode.freeform;
  List<Rect> _presetRects = [];
  int _selectedPresetIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializePresets();
    _updateSelectedRect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AreaSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _updateSelectedRect();
    }
  }

  /// تهيئة الرسوم المتحركة
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  /// تهيئة القوالب المسبقة
  void _initializePresets() {
    _presetRects = [
      const Rect.fromLTWH(100, 100, 800, 600),   // شاشة عادية
      const Rect.fromLTWH(200, 150, 1024, 768),  // شاشة كبيرة
      const Rect.fromLTWH(150, 200, 400, 800),   // شاشة عمودية
      const Rect.fromLTWH(300, 100, 1200, 400),  // شاشة عريضة
    ];
  }

  /// تحديث المنطقة المحددة
  void _updateSelectedRect() {
    setState(() {
      _selectedRect = Rect.fromLTWH(
        widget.config.x.toDouble(),
        widget.config.y.toDouble(),
        widget.config.width.toDouble(),
        widget.config.height.toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط أدوات التحديد
          _buildToolbar(),
          
          // منطقة التحديد الرئيسية
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onTap: _onTap,
                  child: CustomPaint(
                    painter: AreaSelectorPainter(
                      startPoint: _startPoint,
                      endPoint: _endPoint,
                      selectedRect: _selectedRect,
                      isSelecting: _isSelecting,
                      selectionMode: _selectionMode,
                      presetRects: _presetRects,
                      selectedPresetIndex: _selectedPresetIndex,
                      pulseAnimation: _pulseAnimation,
                      showGrid: _showGrid,
                      snapToGrid: _snapToGrid,
                    ),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
          
          // معلومات المنطقة المحددة
          _buildSelectionInfo(),
        ],
      ),
    );
  }

  /// بناء شريط الأدوات
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // أيقونة وعنوان القسم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.crop_free,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'اختيار المنطقة',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // أزرار نمط التحديد
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SegmentedButton<SelectionMode>(
              segments: const [
                ButtonSegment(
                  value: SelectionMode.freeform,
                  label: Text('حر'),
                  icon: Icon(Icons.crop_free),
                ),
                ButtonSegment(
                  value: SelectionMode.preset,
                  label: Text('قوالب'),
                  icon: Icon(Icons.aspect_ratio),
                ),
                ButtonSegment(
                  value: SelectionMode.fullscreen,
                  label: Text('كامل'),
                  icon: Icon(Icons.fullscreen),
                ),
              ],
              selected: {_selectionMode},
              onSelectionChanged: (Set<SelectionMode> selection) {
                setState(() {
                  _selectionMode = selection.first;
                  _handleSelectionModeChange();
                });
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // أزرار الإجراءات
          Row(
            children: [
              _buildActionButton(
                icon: _isSelecting ? Icons.cancel : Icons.select_all,
                label: _isSelecting ? 'إلغاء' : 'تحديد',
                color: _isSelecting ? Colors.red : Colors.green,
                onPressed: _isSelecting ? _cancelSelection : _startSelection,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.refresh,
                label: 'إعادة تعيين',
                color: Colors.orange,
                onPressed: _resetSelection,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: _showGrid ? Icons.grid_off : Icons.grid_on,
                label: _showGrid ? 'إخفاء الشبكة' : 'عرض الشبكة',
                color: Colors.blue,
                onPressed: _toggleGrid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  /// بناء معلومات المنطقة المحددة
  Widget _buildSelectionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // معلومات الأبعاد
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                icon: Icons.location_on,
                label: 'الموضع',
                value: '${widget.config.x}, ${widget.config.y}',
                color: Colors.blue,
              ),
              _buildInfoChip(
                icon: Icons.photo_size_select_large,
                label: 'الحجم',
                value: '${widget.config.width} × ${widget.config.height}',
                color: Colors.green,
              ),
              _buildInfoChip(
                icon: Icons.aspect_ratio,
                label: 'النسبة',
                value: _calculateAspectRatio(),
                color: Colors.orange,
              ),
              _buildInfoChip(
                icon: Icons.straighten,
                label: 'المساحة',
                value: _calculateArea(),
                color: Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // شريط التحكم السريع
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickButton(
                icon: Icons.center_focus_strong,
                label: 'توسيط',
                onPressed: _centerSelection,
              ),
              _buildQuickButton(
                icon: Icons.aspect_ratio,
                label: 'تعديل النسبة',
                onPressed: _adjustAspectRatio,
              ),
              _buildQuickButton(
                icon: Icons.zoom_in,
                label: 'تكبير',
                onPressed: _expandSelection,
              ),
              _buildQuickButton(
                icon: Icons.zoom_out,
                label: 'تصغير',
                onPressed: _shrinkSelection,
              ),
              _buildQuickButton(
                icon: Icons.grid_3x3,
                label: _snapToGrid ? 'إلغاء المحاذاة' : 'محاذاة للشبكة',
                onPressed: _toggleSnapToGrid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء رقاقة معلومات
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء زر سريع
  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.grey.shade700),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// حساب نسبة العرض إلى الارتفاع
  String _calculateAspectRatio() {
    final width = widget.config.width;
    final height = widget.config.height;
    
    if (height == 0) return '∞:1';
    
    final gcd = _gcd(width, height);
    final ratioW = width ~/ gcd;
    final ratioH = height ~/ gcd;
    
    return '$ratioW:$ratioH';
  }

  /// حساب المساحة
  String _calculateArea() {
    final area = widget.config.width * widget.config.height;
    
    if (area > 1000000) {
      return '${(area / 1000000).toStringAsFixed(1)}M';
    } else if (area > 1000) {
      return '${(area / 1000).toStringAsFixed(1)}K';
    } else {
      return '$area px';
    }
  }

  /// حساب القاسم المشترك الأكبر
  int _gcd(int a, int b) {
    while (b != 0) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  /// التعامل مع تغيير نمط التحديد
  void _handleSelectionModeChange() {
    switch (_selectionMode) {
      case SelectionMode.freeform:
        // لا حاجة لإجراء خاص
        break;
      case SelectionMode.preset:
        _showPresetDialog();
        break;
      case SelectionMode.fullscreen:
        _selectFullscreen();
        break;
    }
  }

  /// بدء التحديد
  void _startSelection() {
    setState(() {
      _isSelecting = true;
      _startPoint = null;
      _endPoint = null;
    });
    HapticFeedback.selectionClick();
  }

  /// إلغاء التحديد
  void _cancelSelection() {
    setState(() {
      _isSelecting = false;
      _startPoint = null;
      _endPoint = null;
    });
    HapticFeedback.selectionClick();
  }

  /// إعادة تعيين التحديد
  void _resetSelection() {
    setState(() {
      _selectedRect = const Rect.fromLTWH(0, 0, 800, 600);
    });
    widget.onAreaSelected(0, 0, 800, 600);
    HapticFeedback.mediumImpact();
  }

  /// تبديل عرض الشبكة
  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_showGrid ? 'تم تفعيل الشبكة المساعدة' : 'تم إخفاء الشبكة المساعدة'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// تبديل المحاذاة للشبكة
  void _toggleSnapToGrid() {
    setState(() {
      _snapToGrid = !_snapToGrid;
    });
  }

  /// عرض نافذة القوالب
  void _showPresetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.aspect_ratio),
            SizedBox(width: 8),
            Text('اختيار قالب'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPresetTile('شاشة عادية', '800 × 600', Icons.laptop, 0),
            _buildPresetTile('شاشة كبيرة', '1024 × 768', Icons.desktop_windows, 1),
            _buildPresetTile('شاشة عمودية', '400 × 800', Icons.phone_android, 2),
            _buildPresetTile('شاشة عريضة', '1200 × 400', Icons.tablet, 3),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر قالب
  Widget _buildPresetTile(String title, String subtitle, IconData icon, int index) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: _selectedPresetIndex == index 
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () => _selectPreset(index),
    );
  }

  /// اختيار قالب محدد
  void _selectPreset(int index) {
    Navigator.pop(context);
    setState(() {
      _selectedPresetIndex = index;
      _selectedRect = _presetRects[index];
    });
    
    widget.onAreaSelected(
      _selectedRect!.left.round(),
      _selectedRect!.top.round(),
      _selectedRect!.width.round(),
      _selectedRect!.height.round(),
    );
  }

  /// تحديد الشاشة الكاملة
  void _selectFullscreen() {
    setState(() {
      _selectedRect = const Rect.fromLTWH(0, 0, 1920, 1080);
    });
    widget.onAreaSelected(0, 0, 1920, 1080);
  }

  /// توسيط التحديد
  void _centerSelection() {
    final centerX = (1920 - widget.config.width) / 2;
    final centerY = (1080 - widget.config.height) / 2;
    
    widget.onAreaSelected(
      centerX.round(),
      centerY.round(),
      widget.config.width,
      widget.config.height,
    );
  }

  /// تعديل نسبة العرض إلى الارتفاع
  void _adjustAspectRatio() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.aspect_ratio),
            SizedBox(width: 8),
            Text('تعديل النسبة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAspectRatioTile('16:9', 'شاشة عريضة', Icons.monitor, 16, 9),
            _buildAspectRatioTile('4:3', 'شاشة تقليدية', Icons.tv, 4, 3),
            _buildAspectRatioTile('1:1', 'مربع', Icons.crop_square, 1, 1),
            _buildAspectRatioTile('3:2', 'تصوير', Icons.photo_camera, 3, 2),
            _buildAspectRatioTile('21:9', 'سينمائي', Icons.movie, 21, 9),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر نسبة العرض إلى الارتفاع
  Widget _buildAspectRatioTile(String ratio, String description, IconData icon, int widthRatio, int heightRatio) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(ratio),
      subtitle: Text(description),
      onTap: () => _applyAspectRatio(widthRatio, heightRatio),
    );
  }

  /// تطبيق نسبة عرض إلى ارتفاع
  void _applyAspectRatio(int widthRatio, int heightRatio) {
    Navigator.pop(context);
    
    final currentWidth = widget.config.width;
    final newHeight = (currentWidth * heightRatio / widthRatio).round();
    
    widget.onAreaSelected(
      widget.config.x,
      widget.config.y,
      currentWidth,
      math.min(newHeight, AppConstants.maxHeight),
    );
  }

  /// توسيع التحديد
  void _expandSelection() {
    final newWidth = (widget.config.width * 1.1).round();
    final newHeight = (widget.config.height * 1.1).round();
    
    widget.onAreaSelected(
      widget.config.x,
      widget.config.y,
      math.min(newWidth, AppConstants.maxWidth),
      math.min(newHeight, AppConstants.maxHeight),
    );
  }

  /// تصغير التحديد
  void _shrinkSelection() {
    final newWidth = (widget.config.width * 0.9).round();
    final newHeight = (widget.config.height * 0.9).round();
    
    widget.onAreaSelected(
      widget.config.x,
      widget.config.y,
      math.max(newWidth, AppConstants.minWidth),
      math.max(newHeight, AppConstants.minHeight),
    );
  }

  /// محاذاة للشبكة
  Offset _snapToGridIfEnabled(Offset point) {
    if (!_snapToGrid) return point;
    
    const gridSize = 20.0;
    return Offset(
      (point.dx / gridSize).round() * gridSize,
      (point.dy / gridSize).round() * gridSize,
    );
  }

  /// بداية اللمس
  void _onPanStart(DragStartDetails details) {
    if (!_isSelecting) return;
    
    final snappedPoint = _snapToGridIfEnabled(details.localPosition);
    setState(() {
      _startPoint = snappedPoint;
      _endPoint = snappedPoint;
    });
    HapticFeedback.lightImpact();
  }

  /// تحديث اللمس
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isSelecting || _startPoint == null) return;
    
    final snappedPoint = _snapToGridIfEnabled(details.localPosition);
    setState(() {
      _endPoint = snappedPoint;
    });
  }

  /// انتهاء اللمس
  void _onPanEnd(DragEndDetails details) {
    if (!_isSelecting || _startPoint == null || _endPoint == null) return;
    
    final rect = Rect.fromPoints(_startPoint!, _endPoint!);
    
    // تحويل إحداثيات الويدجت إلى إحداثيات الشاشة
    final screenRect = _widgetToScreenRect(rect);
    
    // تطبيق قيود الحد الأدنى والأقصى
    final x = math.max(0, screenRect.left.round());
    final y = math.max(0, screenRect.top.round());
    final width = math.max(
      AppConstants.minWidth,
      math.min(AppConstants.maxWidth, screenRect.width.abs().round()),
    );
    final height = math.max(
      AppConstants.minHeight,
      math.min(AppConstants.maxHeight, screenRect.height.abs().round()),
    );
    
    widget.onAreaSelected(x, y, width, height);
    
    setState(() {
      _isSelecting = false;
      _startPoint = null;
      _endPoint = null;
    });
    
    HapticFeedback.mediumImpact();
  }

  /// تحويل مستطيل الويدجت إلى إحداثيات الشاشة
  Rect _widgetToScreenRect(Rect widgetRect) {
    // افتراض أن الويدجت يمثل شاشة 1920x1080
    final scaleX = 1920.0 / context.size!.width;
    final scaleY = 1080.0 / context.size!.height;
    
    return Rect.fromLTWH(
      widgetRect.left * scaleX,
      widgetRect.top * scaleY,
      widgetRect.width * scaleX,
      widgetRect.height * scaleY,
    );
  }

  /// النقر المفرد
  void _onTap() {
    if (_isSelecting) {
      _cancelSelection();
    }
  }
}

/// أنماط التحديد المختلفة
enum SelectionMode {
  freeform,   // تحديد حر
  preset,     // قوالب محددة مسبقاً
  fullscreen, // الشاشة الكاملة
}

/// رسام منطقة التحديد
class AreaSelectorPainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;
  final Rect? selectedRect;
  final bool isSelecting;
  final SelectionMode selectionMode;
  final List<Rect> presetRects;
  final int selectedPresetIndex;
  final Animation<double> pulseAnimation;
  final bool showGrid;
  final bool snapToGrid;

  AreaSelectorPainter({
    this.startPoint,
    this.endPoint,
    this.selectedRect,
    required this.isSelecting,
    required this.selectionMode,
    required this.presetRects,
    required this.selectedPresetIndex,
    required this.pulseAnimation,
    required this.showGrid,
    required this.snapToGrid,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    // رسم الخلفية
    _drawBackground(canvas, size);
    
    // رسم الشبكة إذا كانت مفعلة
    if (showGrid) {
      _drawGrid(canvas, size);
    }
    
    // رسم القوالب إذا كان النمط مفعلاً
    if (selectionMode == SelectionMode.preset) {
      _drawPresets(canvas, size);
    }
    
    // رسم المنطقة المحددة حالياً
    if (selectedRect != null) {
      _drawSelectedRect(canvas, size);
    }   

    // رسم التحديد الحر
    if (isSelecting && startPoint != null && endPoint != null) {
        _drawFreeformSelection(canvas, size);
    }
    }
    /// رسم الخلفية
    void _drawBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        backgroundPaint,
    );
    }
    /// رسم الشبكة
    void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    }   
    /// رسم القوالب المحددة مسبقاً
    void _drawPresets(Canvas canvas, Size size) {
    final presetPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    final presetBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final rect in presetRects) {
      canvas.drawRect(rect, presetPaint);
      canvas.drawRect(rect, presetBorderPaint);
    }
  } 

    /// رسم المنطقة المحددة 
    void _drawSelectedRect(Canvas canvas, Size size) {
    final selectedPaint = Paint()
        ..color = Colors.red.withOpacity(0.3);
    if (selectedRect != null) {
      canvas.drawRect(selectedRect!, selectedPaint);
    }
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    if (selectedRect != null) {
      canvas.drawRect(selectedRect!, borderPaint);
    }
  } 
    /// رسم التحديد الحر    
    void _drawFreeformSelection(Canvas canvas, Size size) {
    final selectionPaint = Paint()
      ..color = Colors.green.withOpacity(0.3);
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final rect = Rect.fromPoints(startPoint!, endPoint!);
    canvas.drawRect(rect, selectionPaint);
    canvas.drawRect(rect, borderPaint);         
    // رسم تأثير النبض
    final pulseRadius = 10.0 + (pulseAnimation.value * 10.0
    );
    final pulsePaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(rect.center.dx, rect.center.dy),
        pulseRadius,
        pulsePaint,
    );
  }     
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) {
      return true;
    }   
}

    