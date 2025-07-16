// lib/ui/screens/preview_screen.dart
// شاشة المعاينة - تعرض الصور الملتقطة ونتيجة الدمج

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/scroll_detection.dart';

class PreviewScreen extends StatefulWidget {
  final List<CapturedImage> capturedImages;
  final Future<String?> Function() onSave;

  const PreviewScreen({
    super.key,
    required this.capturedImages,
    required this.onSave,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  int _selectedImageIndex = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة السكرين شوت'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveImage,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'حفظ الصورة',
          ),
        ],
      ),
      body: widget.capturedImages.isEmpty
          ? const Center(
              child: Text('لا توجد صور لعرضها'),
            )
          : Row(
              children: [
                // قائمة الصور الجانبية
                SizedBox(
                  width: 200,
                  child: _buildImageList(),
                ),
                
                const VerticalDivider(),
                
                // منطقة المعاينة الرئيسية
                Expanded(
                  child: _buildMainPreview(),
                ),
              ],
            ),
    );
  }

  /// بناء قائمة الصور الجانبية
  Widget _buildImageList() {
    return Column(
      children: [
        // عنوان القائمة
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'الصور الملتقطة (${widget.capturedImages.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        
        // قائمة الصور
        Expanded(
          child: ListView.builder(
            itemCount: widget.capturedImages.length,
            itemBuilder: (context, index) {
              final image = widget.capturedImages[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      image.imageData,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text('صورة ${index + 1}'),
                subtitle: Text(
                  _formatTimestamp(image.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                selected: _selectedImageIndex == index,
                onTap: () {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// بناء منطقة المعاينة الرئيسية
  Widget _buildMainPreview() {
    final selectedImage = widget.capturedImages[_selectedImageIndex];
    
    return Column(
      children: [
        // شريط المعلومات
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الصورة ${_selectedImageIndex + 1} من ${widget.capturedImages.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _formatTimestamp(selectedImage.timestamp),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        
        // منطقة عرض الصورة
        Expanded(
          child: Center(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.memory(
                selectedImage.imageData,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        // أزرار التنقل
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _selectedImageIndex > 0
                    ? () => setState(() => _selectedImageIndex--)
                    : null,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'الصورة السابقة',
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showMergedPreview(),
                icon: const Icon(Icons.merge_type),
                label: const Text('عرض الصورة المدمجة'),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _selectedImageIndex < widget.capturedImages.length - 1
                    ? () => setState(() => _selectedImageIndex++)
                    : null,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'الصورة التالية',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// تنسيق الوقت
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// عرض نافذة المعاينة المدمجة
  void _showMergedPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الصورة المدمجة'),
        content: const Text(
          'سيتم دمج جميع الصور في صورة واحدة طويلة. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createMergedPreview();
            },
            child: const Text('دمج'),
          ),
        ],
      ),
    );
  }

  /// إنشاء معاينة مدمجة
  Future<void> _createMergedPreview() async {
    // يمكن تنفيذ معاينة الصورة المدمجة هنا
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إنشاء المعاينة المدمجة...'),
      ),
    );
  }

  /// حفظ الصورة
  Future<void> _saveImage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final savedPath = await widget.onSave();
      
      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الصورة في: $savedPath'),
            action: SnackBarAction(
              label: 'فتح المجلد',
              onPressed: () {
                // فتح مدير الملفات
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حفظ الصورة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}