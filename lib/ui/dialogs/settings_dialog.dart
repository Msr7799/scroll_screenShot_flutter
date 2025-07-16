// lib/ui/dialogs/settings_dialog.dart
// نافذة الإعدادات - تحتوي على إعدادات متقدمة للتطبيق

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/screenshot_config.dart';
import '../../services/file_manager.dart';
import '../../utils/constants.dart';

class SettingsDialog extends StatefulWidget {
  final ScreenshotConfig config;
  final Function(ScreenshotConfig) onConfigChanged;

  const SettingsDialog({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScreenshotConfig _tempConfig;
  final FileManager _fileManager = FileManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tempConfig = widget.config;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        child: Column(
          children: [
            // عنوان النافذة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'إعدادات التطبيق',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // تبويبات الإعدادات
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.camera_alt), text: 'الالتقاط'),
                Tab(icon: Icon(Icons.mouse), text: 'السكرول'),
                Tab(icon: Icon(Icons.save), text: 'الحفظ'),
              ],
            ),
            
            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCaptureSettings(),
                  _buildScrollSettings(),
                  _buildSaveSettings(),
                ],
              ),
            ),
            
            // أزرار الإجراءات
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء إعدادات الالتقاط
  Widget _buildCaptureSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            title: 'جودة الصورة',
            child: Column(
              children: [
                ListTile(
                  title: const Text('الجودة'),
                  subtitle: Slider(
                    value: _tempConfig.quality,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: '${(_tempConfig.quality * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        _tempConfig = _tempConfig.copyWith(quality: value);
                      });
                    },
                  ),
                ),
                Text('الجودة الحالية: ${(_tempConfig.quality * 100).round()}%'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'تنسيق الملف',
            child: Column(
              children: AppConstants.supportedFormats.map((format) {
                return RadioListTile<String>(
                  title: Text(format.toUpperCase()),
                  value: format,
                  groupValue: _tempConfig.format,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _tempConfig = _tempConfig.copyWith(format: value);
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'خيارات متقدمة',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('ضغط الصورة'),
                  subtitle: const Text('تقليل حجم الملف'),
                  value: _tempConfig.quality < 1.0,
                  onChanged: (value) {
                    setState(() {
                      _tempConfig = _tempConfig.copyWith(
                        quality: value ? 0.8 : 1.0,
                      );
                    });
                  },
                ),
                ListTile(
                  title: const Text('الحد الأدنى للعرض'),
                  subtitle: Text('${AppConstants.minWidth} بكسل'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () => _showInfoDialog('الحد الأدنى للعرض هو ${AppConstants.minWidth} بكسل'),
                ),
                ListTile(
                  title: const Text('الحد الأقصى للعرض'),
                  subtitle: Text('${AppConstants.maxWidth} بكسل'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () => _showInfoDialog('الحد الأقصى للعرض هو ${AppConstants.maxWidth} بكسل'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء إعدادات السكرول
  Widget _buildScrollSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            title: 'إعدادات السكرول الأساسية',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('تفعيل السكرول التلقائي'),
                  subtitle: const Text('التمرير التلقائي للصفحة'),
                  value: _tempConfig.includeScrolling,
                  onChanged: (value) {
                    setState(() {
                      _tempConfig = _tempConfig.copyWith(includeScrolling: value);
                    });
                  },
                ),
                if (_tempConfig.includeScrolling) ...[
                  ListTile(
                    title: const Text('تأخير السكرول'),
                    subtitle: Slider(
                      value: _tempConfig.scrollDelay.toDouble(),
                      min: AppConstants.minScrollDelay.toDouble(),
                      max: AppConstants.maxScrollDelay.toDouble(),
                      divisions: 49,
                      label: '${_tempConfig.scrollDelay} ms',
                      onChanged: (value) {
                        setState(() {
                          _tempConfig = _tempConfig.copyWith(scrollDelay: value.round());
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('خطوة السكرول'),
                    subtitle: Slider(
                      value: _tempConfig.scrollStep.toDouble(),
                      min: 50,
                      max: 500,
                      divisions: 45,
                      label: '${_tempConfig.scrollStep} px',
                      onChanged: (value) {
                        setState(() {
                          _tempConfig = _tempConfig.copyWith(scrollStep: value.round());
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_tempConfig.includeScrolling)
            _buildSettingsCard(
              title: 'الكشف التلقائي',
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('اكتشاف نهاية المحتوى'),
                    subtitle: const Text('التوقف عند انتهاء المحتوى'),
                    value: _tempConfig.autoDetectEnd,
                    onChanged: (value) {
                      setState(() {
                        _tempConfig = _tempConfig.copyWith(autoDetectEnd: value);
                      });
                    },
                  ),
                  ListTile(
                    title: const Text('حساسية الكشف'),
                    subtitle: const Text('مستوى حساسية اكتشاف التغيير'),
                    trailing: DropdownButton<String>(
                      value: 'متوسط',
                      items: ['منخفض', 'متوسط', 'عالي']
                          .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ))
                          .toList(),
                      onChanged: (value) {
                        // يمكن تطبيق حساسية مختلفة هنا
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'خيارات السكرول المتقدمة',
            child: Column(
              children: [
                ListTile(
                  title: const Text('نوع السكرول'),
                  subtitle: const Text('طريقة تنفيذ السكرول'),
                  trailing: DropdownButton<String>(
                    value: 'عجلة الماوس',
                    items: ['عجلة الماوس', 'مفاتيح الأسهم', 'شريط التمرير']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      // يمكن تطبيق أنواع سكرول مختلفة
                    },
                  ),
                ),
                ListTile(
                  title: const Text('عدد مرات السكرول'),
                  subtitle: const Text('عدد النقرات في كل مرة'),
                  trailing: DropdownButton<int>(
                    value: 3,
                    items: [1, 2, 3, 4, 5]
                        .map((count) => DropdownMenuItem(
                              value: count,
                              child: Text(count.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      // يمكن تطبيق عدد مختلف من النقرات
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء إعدادات الحفظ
  Widget _buildSaveSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsCard(
            title: 'مسار الحفظ الافتراضي',
            child: Column(
              children: [
                ListTile(
                  title: const Text('المسار الحالي'),
                  subtitle: Text(_tempConfig.outputPath),
                  trailing: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _selectOutputPath,
                  ),
                ),
                ListTile(
                  title: const Text('استخدام المسار الافتراضي'),
                  subtitle: const Text('مجلد المستندات/Screenshots'),
                  trailing: ElevatedButton(
                    onPressed: _setDefaultPath,
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'خيارات الحفظ',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('حفظ تلقائي'),
                  subtitle: const Text('حفظ الصورة مباشرة بعد الالتقاط'),
                  value: false, // يمكن إضافة هذا الخيار للكونفيج
                  onChanged: (value) {
                    // تطبيق الحفظ التلقائي
                  },
                ),
                SwitchListTile(
                  title: const Text('إضافة التاريخ للاسم'),
                  subtitle: const Text('إضافة التاريخ والوقت لاسم الملف'),
                  value: true,
                  onChanged: (value) {
                    // تطبيق إضافة التاريخ
                  },
                ),
                ListTile(
                  title: const Text('تسمية الملف'),
                  subtitle: const Text('نمط تسمية الملفات'),
                  trailing: DropdownButton<String>(
                    value: 'screenshot_timestamp',
                    items: [
                      'screenshot_timestamp',
                      'capture_datetime',
                      'scroll_capture_number'
                    ].map((pattern) => DropdownMenuItem(
                          value: pattern,
                          child: Text(pattern),
                        ))
                        .toList(),
                    onChanged: (value) {
                      // تطبيق نمط التسمية
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildSettingsCard(
            title: 'الإعدادات العامة',
            child: Column(
              children: [
                ListTile(
                  title: const Text('حفظ الإعدادات'),
                  subtitle: const Text('حفظ الإعدادات الحالية كافتراضية'),
                  trailing: ElevatedButton(
                    onPressed: _saveAsDefault,
                    child: const Text('حفظ'),
                  ),
                ),
                ListTile(
                  title: const Text('استعادة الإعدادات الافتراضية'),
                  subtitle: const Text('إعادة تعيين جميع الإعدادات'),
                  trailing: ElevatedButton(
                    onPressed: _resetToDefault,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('استعادة'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة إعدادات
  Widget _buildSettingsCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  /// اختيار مسار الحفظ
  Future<void> _selectOutputPath() async {
    // يمكن استخدام file_picker هنا
    final newPath = await _fileManager.getDefaultPicturesDirectory();
    setState(() {
      _tempConfig = _tempConfig.copyWith(outputPath: newPath);
    });
  }

  /// تعيين المسار الافتراضي
  Future<void> _setDefaultPath() async {
    final defaultPath = await _fileManager.getDefaultPicturesDirectory();
    setState(() {
      _tempConfig = _tempConfig.copyWith(outputPath: defaultPath);
    });
  }

  /// حفظ كافتراضي
  Future<void> _saveAsDefault() async {
    await _fileManager.saveSettings(_tempConfig.toMap());
    _showSuccessMessage('تم حفظ الإعدادات بنجاح');
  }

  /// استعادة الإعدادات الافتراضية
  void _resetToDefault() {
    setState(() {
      _tempConfig = ScreenshotConfig(
        x: 0,
        y: 0,
        width: AppConstants.defaultWidth,
        height: AppConstants.defaultHeight,
        outputPath: AppConstants.defaultOutputPath,
      );
    });
  }

  /// حفظ الإعدادات
  void _saveSettings() {
    widget.onConfigChanged(_tempConfig);
    Navigator.pop(context);
  }

  /// عرض رسالة نجاح
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// عرض معلومات
  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}