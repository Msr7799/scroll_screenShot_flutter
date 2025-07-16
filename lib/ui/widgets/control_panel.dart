// lib/ui/widgets/control_panel.dart
// لوحة التحكم - تحتوي على أزرار التحكم والإعدادات

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/screenshot_config.dart';

class ControlPanel extends StatefulWidget {
  final ScreenshotConfig config;
  final Function(ScreenshotConfig) onConfigChanged;
  final VoidCallback onStartCapture;
  final VoidCallback onStopCapture;
  final VoidCallback onPauseCapture;
  final VoidCallback onResumeCapture;

  const ControlPanel({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.onStartCapture,
    required this.onStopCapture,
    required this.onPauseCapture,
    required this.onResumeCapture,
  });

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  late TextEditingController _xController;
  late TextEditingController _yController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _outputPathController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  /// تهيئة متحكمات النصوص
  void _initializeControllers() {
    _xController = TextEditingController(text: widget.config.x.toString());
    _yController = TextEditingController(text: widget.config.y.toString());
    _widthController = TextEditingController(text: widget.config.width.toString());
    _heightController = TextEditingController(text: widget.config.height.toString());
    _outputPathController = TextEditingController(text: widget.config.outputPath);
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _outputPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عنوان اللوحة
            Text(
              'لوحة التحكم',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // إعدادات المنطقة
            _buildSectionTitle('إعدادات المنطقة'),
            _buildDimensionFields(),
            
            const SizedBox(height: 16),
            
            // إعدادات السكرول
            _buildSectionTitle('إعدادات السكرول'),
            _buildScrollSettings(),
            
            const SizedBox(height: 16),
            
            // إعدادات الحفظ
            _buildSectionTitle('إعدادات الحفظ'),
            _buildSaveSettings(),
            
            const SizedBox(height: 24),
            
            // أزرار التحكم
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  /// بناء عنوان القسم
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// بناء حقول الأبعاد
  Widget _buildDimensionFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _xController,
                decoration: const InputDecoration(
                  labelText: 'X',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateConfig(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _yController,
                decoration: const InputDecoration(
                  labelText: 'Y',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateConfig(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _widthController,
                decoration: const InputDecoration(
                  labelText: 'العرض',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateConfig(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'الارتفاع',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateConfig(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// بناء إعدادات السكرول
  Widget _buildScrollSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('تفعيل السكرول'),
          value: widget.config.includeScrolling,
          onChanged: (value) {
            widget.onConfigChanged(
              widget.config.copyWith(includeScrolling: value),
            );
          },
        ),
        if (widget.config.includeScrolling) ...[
          ListTile(
            title: const Text('تأخير السكرول'),
            subtitle: Slider(
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
          ),
          SwitchListTile(
            title: const Text('اكتشاف تلقائي للنهاية'),
            value: widget.config.autoDetectEnd,
            onChanged: (value) {
              widget.onConfigChanged(
                widget.config.copyWith(autoDetectEnd: value),
              );
            },
          ),
        ],
      ],
    );
  }

  /// بناء إعدادات الحفظ
  Widget _buildSaveSettings() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _outputPathController,
                decoration: const InputDecoration(
                  labelText: 'مسار الحفظ',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
            ),
            IconButton(
              onPressed: _selectOutputPath,
              icon: const Icon(Icons.folder_open),
              tooltip: 'اختيار المجلد',
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.config.format,
          decoration: const InputDecoration(
            labelText: 'تنسيق الملف',
            border: OutlineInputBorder(),
          ),
          items: ['png', 'jpg', 'bmp', 'tiff']
              .map((format) => DropdownMenuItem(
                    value: format,
                    child: Text(format.toUpperCase()),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onConfigChanged(
                widget.config.copyWith(format: value),
              );
            }
          },
        ),
      ],
    );
  }

  /// بناء أزرار التحكم
  Widget _buildControlButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: widget.onStartCapture,
          icon: const Icon(Icons.play_arrow),
          label: const Text('بدء الالتقاط'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onPauseCapture,
                icon: const Icon(Icons.pause),
                label: const Text('إيقاف مؤقت'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onResumeCapture,
                icon: const Icon(Icons.play_arrow),
                label: const Text('استئناف'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: widget.onStopCapture,
          icon: const Icon(Icons.stop),
          label: const Text('إيقاف نهائي'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
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
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _outputPathController.text = result;
      });
      widget.onConfigChanged(
        widget.config.copyWith(outputPath: result),
      );
    }
  }
}