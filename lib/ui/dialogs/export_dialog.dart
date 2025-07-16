// lib/ui/dialogs/export_dialog.dart
// نافذة التصدير - تحتوي على خيارات تصدير الصور

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:typed_data';
import '../../models/scroll_detection.dart';
import '../../services/file_manager.dart';

class ExportDialog extends StatefulWidget {
  final List<CapturedImage> images;
  final Function(String format, String quality, String naming) onExport;

  const ExportDialog({
    super.key,
    required this.images,
    required this.onExport,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _selectedFormat = 'png';
  String _selectedQuality = 'high';
  String _selectedNaming = 'timestamp';
  bool _mergeImages = true;
  bool _addWatermark = false;
  Color _watermarkColor = Colors.white;
  String _watermarkText = 'Screenshot Tool';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download),
          SizedBox(width: 8),
          Text('تصدير الصور'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات الصور
              _buildInfoCard(),
              
              const SizedBox(height: 16),
              
              // خيارات التصدير
              _buildExportOptions(),
              
              const SizedBox(height: 16),
              
              // خيارات متقدمة
              _buildAdvancedOptions(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _exportImages,
          icon: const Icon(Icons.download),
          label: const Text('تصدير'),
        ),
      ],
    );
  }

  /// بناء بطاقة المعلومات
  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات الصور',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('عدد الصور: ${widget.images.length}'),
            Text('التاريخ: ${DateTime.now().toString().split(' ')[0]}'),
            Text('الحجم التقديري: ${_calculateSize()}'),
          ],
        ),
      ),
    );
  }

  /// بناء خيارات التصدير
  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خيارات التصدير',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // تنسيق الملف
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'تنسيق الملف',
            border: OutlineInputBorder(),
          ),
          value: _selectedFormat,
          items: [
            const DropdownMenuItem(value: 'png', child: Text('PNG - جودة عالية')),
            const DropdownMenuItem(value: 'jpg', child: Text('JPG - حجم أصغر')),
            const DropdownMenuItem(value: 'pdf', child: Text('PDF - مستند')),
            const DropdownMenuItem(value: 'gif', child: Text('GIF - متحرك')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFormat = value!;
            });
          },
        ),
        
        const SizedBox(height: 12),
        
        // جودة الصورة
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'جودة الصورة',
            border: OutlineInputBorder(),
          ),
          value: _selectedQuality,
          items: const [
            DropdownMenuItem(value: 'high', child: Text('عالية - 100%')),
            DropdownMenuItem(value: 'medium', child: Text('متوسطة - 80%')),
            DropdownMenuItem(value: 'low', child: Text('منخفضة - 60%')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedQuality = value!;
            });
          },
        ),
        
        const SizedBox(height: 12),
        
        // نمط التسمية
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'نمط تسمية الملف',
            border: OutlineInputBorder(),
          ),
          value: _selectedNaming,
          items: const [
            DropdownMenuItem(value: 'timestamp', child: Text('التاريخ والوقت')),
            DropdownMenuItem(value: 'sequence', child: Text('رقم تسلسلي')),
            DropdownMenuItem(value: 'custom', child: Text('مخصص')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedNaming = value!;
            });
          },
        ),
      ],
    );
  }

  /// بناء الخيارات المتقدمة
  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خيارات متقدمة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // دمج الصور
        SwitchListTile(
          title: const Text('دمج جميع الصور'),
          subtitle: const Text('إنشاء صورة واحدة طويلة'),
          value: _mergeImages,
          onChanged: (value) {
            setState(() {
              _mergeImages = value;
            });
          },
        ),
        
        // إضافة علامة مائية
        SwitchListTile(
          title: const Text('إضافة علامة مائية'),
          subtitle: const Text('إضافة نص أو شعار على الصورة'),
          value: _addWatermark,
          onChanged: (value) {
            setState(() {
              _addWatermark = value;
            });
          },
        ),
        
        // إعدادات العلامة المائية
        if (_addWatermark) ...[
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'نص العلامة المائية',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _watermarkText = value;
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('لون العلامة المائية:'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickWatermarkColor,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _watermarkColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        
        // معاينة
        if (widget.images.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _showPreview,
            icon: const Icon(Icons.visibility),
            label: const Text('معاينة قبل التصدير'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade700,
            ),
          ),
      ],
    );
  }

  /// اختيار لون العلامة المائية
  void _pickWatermarkColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختيار اللون'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _watermarkColor,
            onColorChanged: (color) {
              setState(() {
                _watermarkColor = color;
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض معاينة
  void _showPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معاينة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('التنسيق: ${_selectedFormat.toUpperCase()}'),
            Text('الجودة: $_selectedQuality'),
            Text('نمط التسمية: $_selectedNaming'),
            Text('دمج الصور: ${_mergeImages ? 'نعم' : 'لا'}'),
            Text('علامة مائية: ${_addWatermark ? 'نعم' : 'لا'}'),
            if (_addWatermark) Text('نص العلامة: $_watermarkText'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// حساب الحجم التقديري
  String _calculateSize() {
    final avgSize = widget.images.isNotEmpty 
        ? widget.images.first.imageData.length 
        : 0;
    final totalSize = avgSize * widget.images.length;
    
    if (totalSize > 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (totalSize > 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$totalSize bytes';
    }
  }

  /// تصدير الصور
  void _exportImages() {
    // استدعاء دالة التصدير
    widget.onExport(_selectedFormat, _selectedQuality, _selectedNaming);
    
    Navigator.pop(context);
    
    //## 9. lib/ui/widgets/area_selector.dart
```dart
// lib/ui/widgets/area_selector.dart
// محدد المنطقة - يسمح بتحديد منطقة السكرين شوت بصرياً

import 'package:flutter/material.dart';
import '../../models/screenshot_config.dart';

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

class _AreaSelectorState extends State<AreaSelector> {
  bool _isSelecting = false;
  Offset? _startPoint;
  Offset? _endPoint;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عنوان القسم
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'اختيار المنطقة',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: _toggleSelection,
                  icon: Icon(_isSelecting ? Icons.cancel : Icons.select_all),
                  label: Text(_isSelecting ? 'إلغاء' : 'تحديد'),
                ),
              ],
            ),
          ),
          
          // منطقة التحديد
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: AreaSelectorPainter(
                    startPoint: _startPoint,
                    endPoint: _endPoint,
                    isSelecting: _isSelecting,
                    config: widget.config,
                  ),
                  child: Container(),
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
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('الموضع X', widget.config.x.toString()),
              _buildInfoItem('الموضع Y', widget.config.y.toString()),
              _buildInfoItem('العرض', widget.config.width.toString()),
              _buildInfoItem('الارتفاع', widget.config.height.toString()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'المنطقة: ${widget.config.width} × ${widget.config.height} بكسل',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر معلومات
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// تبديل حالة التحديد
  void _toggleSelection() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _startPoint = null;
        _endPoint = null;
      }
    });
  }

  /// بداية عملية التحديد
  void _onPanStart(DragStartDetails details) {
    if (!_isSelecting) return;
    
    setState(() {
      _startPoint = details.localPosition;
      _endPoint = details.localPosition;
    });
  }

  /// تحديث عملية التحديد
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isSelecting || _startPoint == null) return;
    
    setState(() {
      _endPoint = details.localPosition;
    });
  }

  /// انتهاء عملية التحديد
  void _onPanEnd(DragEndDetails details) {
    if (!_isSelecting || _startPoint == null || _endPoint == null) return;
    
    // حساب المنطقة المحددة
    final x = _startPoint!.dx.round();
    final y = _startPoint!.dy.round();
    final width = (_endPoint!.dx - _startPoint!.dx).abs().round();
    final height = (_endPoint!.dy - _startPoint!.dy).abs().round();
    
    // تحديث الإعدادات
    widget.onAreaSelected(x, y, width, height);
    
    // إنهاء عملية التحديد
    setState(() {
      _isSelecting = false;
      _startPoint = null;
      _endPoint = null;
    });
  }
}

/// رسام منطقة التحديد
class AreaSelectorPainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;
  final bool isSelecting;
  final ScreenshotConfig config;

  AreaSelectorPainter({
    this.startPoint,
    this.endPoint,
    required this.isSelecting,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // رسم الخلفية
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    
    // رسم المنطقة المحددة حالياً
    if (config.width > 0 && config.height > 0) {
      _drawCurrentSelection(canvas, size);
    }
    
    // رسم منطقة التحديد الجديدة
    if (isSelecting && startPoint != null && endPoint != null) {
      _drawNewSelection(canvas);
    }
  }

  /// رسم المنطقة المحددة حالياً
  void _drawCurrentSelection(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // تحويل الإحداثيات إلى نسبة من حجم الويدجت
    final rect = Rect.fromLTWH(
      config.x * size.width / 1920, // نسبة من دقة الشاشة
      config.y * size.height / 1080,
      config.width * size.width / 1920,
      config.height * size.height / 1080,
    );
    
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
    
    // رسم معلومات المنطقة
    _drawSelectionInfo(canvas, rect);
  }

  /// رسم منطقة التحديد الجديدة
  void _drawNewSelection(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final rect = Rect.fromPoints(startPoint!, endPoint!);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
    
    // رسم خطوط التوجيه
    _drawGuideLines(canvas, rect);
  }

  /// رسم خطوط التوجيه
  void _drawGuideLines(Canvas canvas, Rect rect) {
    final guidePaint = Paint()
      ..color = Colors.green.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // خطوط عمودية
    canvas.drawLine(
      Offset(rect.left, 0),
      Offset(rect.left, rect.top),
      guidePaint,
    );
    canvas.drawLine(
      Offset(rect.right, 0),
      Offset(rect.right, rect.top),
      guidePaint,
    );
    
    // خطوط أفقية
    canvas.drawLine(
      Offset(0, rect.top),
      Offset(rect.left, rect.top),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, rect.bottom),
      Offset(rect.left, rect.bottom),
      guidePaint,
    );
  }

  /// رسم معلومات المنطقة
  void _drawSelectionInfo(Canvas canvas, Rect rect) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${rect.width.round()} × ${rect.height.round()}',
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(rect.left + 5, rect.top + 5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}