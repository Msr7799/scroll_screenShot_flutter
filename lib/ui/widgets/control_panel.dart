// lib/ui/widgets/control_panel.dart
// لوحة التحكم المحدثة مع زر تحديد المنطقة الجديد

import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/screenshot_config.dart';

class ControlPanel extends StatefulWidget {
  final ScreenshotConfig config;
  final Function(ScreenshotConfig) onConfigChanged;
  final VoidCallback onStartCapture;
  final VoidCallback onStopCapture;
  final VoidCallback onPauseCapture;
  final VoidCallback onResumeCapture;
  final VoidCallback onSelectArea;

  const ControlPanel({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.onStartCapture,
    required this.onStopCapture,
    required this.onPauseCapture,
    required this.onResumeCapture,
    required this.onSelectArea,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> with TickerProviderStateMixin {
  late TextEditingController _xController;
  late TextEditingController _yController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _outputPathController;
  late AnimationController _selectButtonController;
  late Animation<double> _selectButtonAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _disposeControllers();
    _selectButtonController.dispose();
    super.dispose();
  }

  /// تهيئة متحكمات النصوص
  void _initializeControllers() {
    _xController = TextEditingController(text: widget.config.x.toString());
    _yController = TextEditingController(text: widget.config.y.toString());
    _widthController = TextEditingController(text: widget.config.width.toString());
    _heightController = TextEditingController(text: widget.config.height.toString());
    _outputPathController = TextEditingController(text: widget.config.outputPath);
  }

  /// تهيئة الرسوم المتحركة
  void _initializeAnimations() {
    _selectButtonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _selectButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _selectButtonController,
      curve: Curves.easeInOut,
    ));
    
    _selectButtonController.repeat(reverse: true);
  }

  /// تنظيف متحكمات النصوص
  void _disposeControllers() {
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _outputPathController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.02),
              Colors.blue.withOpacity(0.01),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // عنوان اللوحة
              _buildPanelHeader(),
              const SizedBox(height: 20),
              
              // زر تحديد المنطقة الرئيسي
              _buildAreaSelectionButton(),
              const SizedBox(height: 24),
              
              // إعدادات المنطقة
              _buildSectionTitle('إعدادات المنطقة', Icons.crop_free),
              _buildDimensionFields(),
              const SizedBox(height: 20),
              
              // إعدادات السكرول
              _buildSectionTitle('إعدادات السكرول', Icons.mouse),
              _buildScrollSettings(),
              const SizedBox(height: 20),
              
              // إعدادات الحفظ
              _buildSectionTitle('إعدادات الحفظ', Icons.save),
              _buildSaveSettings(),
              const SizedBox(height: 24),
              
              // أزرار التحكم
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء عنوان اللوحة
  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة التحكم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'إعداد وتشغيل عملية الالتقاط',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر تحديد المنطقة الرئيسي
  Widget _buildAreaSelectionButton() {
    return AnimatedBuilder(
      animation: _selectButtonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _selectButtonAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF45A049),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onSelectArea,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.crop_free,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحديد المنطقة من الشاشة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'اضغط لإخفاء النافذة وتحديد المنطقة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// بناء عنوان القسم
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حقول الأبعاد
  Widget _buildDimensionFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // الموضع X و Y
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _xController,
                  label: 'الموضع X',
                  icon: Icons.horizontal_rule,
                  onChanged: (value) => _updateConfig(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _yController,
                  label: 'الموضع Y',
                  icon: Icons.vertical_align_center,
                  onChanged: (value) => _updateConfig(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // العرض والارتفاع
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _widthController,
                  label: 'العرض',
                  icon: Icons.straighten,
                  onChanged: (value) => _updateConfig(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: 'الارتفاع',
                  icon: Icons.height,
                  onChanged: (value) => _updateConfig(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // معلومات سريعة
          _buildQuickInfo(),
        ],
      ),
    );
  }

  /// بناء حقل نص مخصص
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
    );
  }

  /// بناء معلومات سريعة
  Widget _buildQuickInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            'المساحة',
            '${widget.config.width * widget.config.height} px',
            Icons.aspect_ratio,
          ),
          _buildInfoItem(
            'النسبة',
            _calculateAspectRatio(),
            Icons.crop,
          ),
        ],
      ),
    );
  }

  /// بناء عنصر معلومات
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  /// بناء إعدادات السكرول
  Widget _buildScrollSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('تفعيل السكرول التلقائي'),
            subtitle: const Text('التمرير التلقائي أثناء الالتقاط'),
            value: widget.config.includeScrolling,
            onChanged: (value) {
              widget.onConfigChanged(
                widget.config.copyWith(includeScrolling: value),
              );
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          if (widget.config.includeScrolling) ...[
            const Divider(),
            
            // تأخير السكرول
            ListTile(
              title: const Text('تأخير السكرول'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: widget.config.scrollDelay.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '${widget.config.scrollDelay} ms',
                    onChanged: (value) {
                      widget.onConfigChanged(
                        widget.config.copyWith(scrollDelay: value.round()),
                      );
                    },
                  ),
                  Text(
                    'الحالي: ${widget.config.scrollDelay} مللي ثانية',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.zero,
            ),
            
            // اكتشاف النهاية
            SwitchListTile(
              title: const Text('اكتشاف تلقائي للنهاية'),
              subtitle: const Text('التوقف عند انتهاء المحتوى'),
              value: widget.config.autoDetectEnd,
              onChanged: (value) {
                widget.onConfigChanged(
                  widget.config.copyWith(autoDetectEnd: value),
                );
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  /// بناء إعدادات الحفظ
  Widget _buildSaveSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // مسار الحفظ
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _outputPathController,
                  decoration: InputDecoration(
                    labelText: 'مسار الحفظ',
                    prefixIcon: const Icon(Icons.folder, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  readOnly: true,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _selectOutputPath,
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  tooltip: 'اختيار المجلد',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // تنسيق الملف
          DropdownButtonFormField<String>(
            value: widget.config.format,
            decoration: InputDecoration(
              labelText: 'تنسيق الملف',
              prefixIcon: const Icon(Icons.image, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            items: [
              _buildDropdownItem('png', 'PNG - جودة عالية'),
              _buildDropdownItem('jpg', 'JPG - حجم أصغر'),
              _buildDropdownItem('bmp', 'BMP - غير مضغوط'),
              _buildDropdownItem('tiff', 'TIFF - احترافي'),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.onConfigChanged(
                  widget.config.copyWith(format: value),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// بناء عنصر قائمة منسدلة
  DropdownMenuItem<String> _buildDropdownItem(String value, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  /// بناء أزرار التحكم
  Widget _buildControlButtons() {
    return Column(
      children: [
        // زر البدء الرئيسي
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onStartCapture,
              borderRadius: BorderRadius.circular(12),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'بدء الالتقاط',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // أزرار التحكم الثانوية
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                icon: Icons.pause,
                label: 'إيقاف مؤقت',
                color: Colors.orange,
                onPressed: widget.onPauseCapture,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSecondaryButton(
                icon: Icons.play_arrow,
                label: 'استئناف',
                color: Colors.blue,
                onPressed: widget.onResumeCapture,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // زر الإيقاف النهائي
        SizedBox(
          width: double.infinity,
          child: _buildSecondaryButton(
            icon: Icons.stop,
            label: 'إيقاف نهائي',
            color: Colors.red,
            onPressed: widget.onStopCapture,
          ),
        ),
      ],
    );
  }

  /// بناء زر ثانوي
  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

  /// حساب القاسم المشترك الأكبر
  int _gcd(int a, int b) {
    while (b != 0) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  /// تحديث الإعدادات
  void _updateConfig() {
    final x = int.tryParse(_xController.text) ?? 0;
    final y = int.tryParse(_yController.text) ?? 0;
    final width = int.tryParse(_widthController.text) ?? 800;
    final height = int.tryParse(_heightController.text) ?? 600;
    
    widget.onConfigChanged(
      widget.config.copyWith(
        x: x,
        y: y,
        width: width,
        height: height,
      ),
    );
  }

  /// اختيار مسار الحفظ
  Future<void> _selectOutputPath() async {
    try {
      // استخدام مربع حوار بسيط لإدخال المسار
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _PathSelectionDialog(
          currentPath: _outputPathController.text,
        ),
      );
      
      if (result != null && result.isNotEmpty) {
        // التحقق من صحة المسار
        final directory = Directory(result);
        if (await directory.exists() || result.startsWith('/')) {
          setState(() {
            _outputPathController.text = result;
          });
          widget.onConfigChanged(
            widget.config.copyWith(outputPath: result),
          );
        } else {
          _showErrorSnackBar('المسار غير صالح: $result');
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار المجلد: $e');
    }
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// تحديث قيم المتحكمات عند تغيير الإعدادات خارجياً
  @override
  void didUpdateWidget(ControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _updateControllers();
    }
  }

  /// تحديث المتحكمات
  void _updateControllers() {
    _xController.text = widget.config.x.toString();
    _yController.text = widget.config.y.toString();
    _widthController.text = widget.config.width.toString();
    _heightController.text = widget.config.height.toString();
    _outputPathController.text = widget.config.outputPath;
  }
}

/// مربع حوار اختيار المسار
class _PathSelectionDialog extends StatefulWidget {
  final String currentPath;
  
  const _PathSelectionDialog({required this.currentPath});
  
  @override
  State<_PathSelectionDialog> createState() => _PathSelectionDialogState();
}

class _PathSelectionDialogState extends State<_PathSelectionDialog> {
  late TextEditingController _pathController;
  
  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.currentPath);
  }
  
  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.folder_open),
          SizedBox(width: 8),
          Text('اختيار مسار الحفظ'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              labelText: 'مسار المجلد',
              hintText: '/home/user/Pictures/Screenshots',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          const Text(
            'أمثلة على مسارات صالحة:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• /home/user/Pictures'),
              Text('• /home/user/Desktop'),
              Text('• /tmp/screenshots'),
              Text('• /home/user/Documents'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () async {
            // تعيين مسار افتراضي
            final homeDir = Platform.environment['HOME'] ?? '/tmp';
            final defaultPath = '$homeDir/Pictures/Screenshots';
            _pathController.text = defaultPath;
          },
          child: const Text('افتراضي'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _pathController.text.trim());
          },
          child: const Text('موافق'),
        ),
      ],
    );
  }
}