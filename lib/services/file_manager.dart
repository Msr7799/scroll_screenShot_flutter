// lib/services/file_manager.dart
// مدير الملفات المحدث مع وظائف إضافية

import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileManager {
  static const Uuid _uuid = Uuid();

  /// حفظ الصورة في المسار المحدد
  Future<String?> saveImage(
    Uint8List imageData,
    String outputPath,
    String format,
  ) async {
    try {
      // إنشاء اسم ملف فريد
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'screenshot_$timestamp.$format';
      
      // تحديد المسار النهائي
      final finalPath = path.join(outputPath, filename);
      
      return await saveImageWithPath(imageData, finalPath);
    } catch (e) {
      print('خطأ في حفظ الصورة: $e');
      return null;
    }
  }

  /// حفظ الصورة بمسار محدد
  Future<String?> saveImageWithPath(Uint8List imageData, String fullPath) async {
    try {
      // التأكد من وجود المجلد
      final directory = Directory(path.dirname(fullPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // حفظ الملف
      final file = File(fullPath);
      await file.writeAsBytes(imageData);
      
      // التحقق من نجاح الحفظ
      if (await file.exists()) {
        final stats = await file.stat();
        print('تم حفظ الصورة: ${path.basename(fullPath)} (${_formatFileSize(stats.size)})');
        return fullPath;
      }
      
      return null;
    } catch (e) {
      print('خطأ في حفظ الصورة بالمسار المحدد: $e');
      return null;
    }
  }

  /// حفظ معلومات إضافية للصورة
  Future<bool> saveMetadata(String metadataPath, Map<String, dynamic> metadata) async {
    try {
      final file = File(metadataPath);
      final jsonString = const JsonEncoder.withIndent('  ').convert(metadata);
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      print('خطأ في حفظ المعلومات الإضافية: $e');
      return false;
    }
  }

  /// الحصول على مجلد الصور الافتراضي
  Future<String> getDefaultPicturesDirectory() async {
    try {
      // محاولة الحصول على مجلد Pictures
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final picturesDir = path.join(homeDir, 'Pictures', 'Screenshots');
        final dir = Directory(picturesDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return picturesDir;
      }
      
      // البديل: استخدام مجلد المستندات
      final directory = await getApplicationDocumentsDirectory();
      final screenshotsDir = path.join(directory.path, 'Screenshots');
      
      final dir = Directory(screenshotsDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      return screenshotsDir;
    } catch (e) {
      print('خطأ في الحصول على مجلد الصور: $e');
      return '/tmp/screenshots';
    }
  }

  /// إنشاء مجلد فرعي بالتاريخ
  Future<String> createDateSubfolder(String basePath) async {
    try {
      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final subfolderPath = path.join(basePath, dateString);
      
      final directory = Directory(subfolderPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      return subfolderPath;
    } catch (e) {
      print('خطأ في إنشاء مجلد فرعي: $e');
      return basePath;
    }
  }

  /// حفظ إعدادات التطبيق
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final settingsFile = File(path.join(directory.path, 'settings.json'));
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(settings);
      await settingsFile.writeAsString(jsonString);
      
      return true;
    } catch (e) {
      print('خطأ في حفظ الإعدادات: $e');
      return false;
    }
  }

  /// تحميل إعدادات التطبيق
  Future<Map<String, dynamic>> loadSettings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final settingsFile = File(path.join(directory.path, 'settings.json'));
      
      if (await settingsFile.exists()) {
        final jsonString = await settingsFile.readAsString();
        return jsonDecode(jsonString);
      }
      
      return {};
    } catch (e) {
      print('خطأ في تحميل الإعدادات: $e');
      return {};
    }
  }

  /// إنشاء ملف مشروع جديد
  Future<String?> createProjectFile(String projectName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final projectsDir = path.join(directory.path, 'Projects');
      
      // إنشاء مجلد المشاريع
      final dir = Directory(projectsDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // إنشاء ملف المشروع
      final projectFile = File(path.join(projectsDir, '$projectName.json'));
      final projectData = {
        'name': projectName,
        'id': _uuid.v4(),
        'created': DateTime.now().toIso8601String(),
        'screenshots': [],
        'settings': {},
        'version': '1.0',
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(projectData);
      await projectFile.writeAsString(jsonString);
      return projectFile.path;
    } catch (e) {
      print('خطأ في إنشاء ملف المشروع: $e');
      return null;
    }
  }

  /// الحصول على قائمة المشاريع
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final projectsDir = Directory(path.join(directory.path, 'Projects'));
      
      if (!await projectsDir.exists()) {
        return [];
      }
      
      final projects = <Map<String, dynamic>>[];
      await for (final entity in projectsDir.list()) {
        if (entity is File && path.extension(entity.path) == '.json') {
          try {
            final content = await entity.readAsString();
            final projectData = jsonDecode(content);
            projects.add(projectData);
          } catch (e) {
            print('خطأ في قراءة مشروع: ${entity.path}');
          }
        }
      }
      
      // ترتيب حسب تاريخ الإنشاء
      projects.sort((a, b) {
        final dateA = DateTime.tryParse(a['created'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['created'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
      
      return projects;
    } catch (e) {
      print('خطأ في الحصول على المشاريع: $e');
      return [];
    }
  }

  /// حذف ملفات قديمة
  Future<void> cleanupOldFiles(String directoryPath, {int maxAgeInDays = 30}) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      final filesToDelete = <File>[];
      
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stats = await entity.stat();
          if (stats.modified.isBefore(cutoffDate)) {
            filesToDelete.add(entity);
          }
        }
      }
      
      for (final file in filesToDelete) {
        try {
          await file.delete();
          print('تم حذف الملف القديم: ${path.basename(file.path)}');
        } catch (e) {
          print('خطأ في حذف الملف: ${file.path}');
        }
      }
      
      print('تم حذف ${filesToDelete.length} ملف قديم');
    } catch (e) {
      print('خطأ في تنظيف الملفات: $e');
    }
  }

  /// الحصول على معلومات استخدام القرص
  Future<Map<String, dynamic>> getDiskUsage(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return {'totalSize': 0, 'fileCount': 0, 'error': 'Directory not found'};
      }
      
      int totalSize = 0;
      int fileCount = 0;
      final fileTypes = <String, int>{};
      
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stats = await entity.stat();
          totalSize += stats.size;
          fileCount++;
          
          final extension = path.extension(entity.path).toLowerCase();
          fileTypes[extension] = (fileTypes[extension] ?? 0) + 1;
        }
      }
      
      return {
        'totalSize': totalSize,
        'totalSizeFormatted': _formatFileSize(totalSize),
        'fileCount': fileCount,
        'fileTypes': fileTypes,
        'averageFileSize': fileCount > 0 ? totalSize ~/ fileCount : 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// تصدير قائمة الصور
  Future<String?> exportImageList(List<String> imagePaths, String exportPath) async {
    try {
      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'total_images': imagePaths.length,
        'images': imagePaths.map((imagePath) {
          final file = File(imagePath);
          return {
            'path': imagePath,
            'filename': path.basename(imagePath),
            'exists': file.existsSync(),
            'size': file.existsSync() ? file.lengthSync() : 0,
          };
        }).toList(),
      };
      
      final exportFile = File(exportPath);
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await exportFile.writeAsString(jsonString);
      
      return exportPath;
    } catch (e) {
      print('خطأ في تصدير قائمة الصور: $e');
      return null;
    }
  }

  /// إنشاء نسخة احتياطية من الإعدادات
  Future<String?> backupSettings() async {
    try {
      final settings = await loadSettings();
      final projects = await getProjects();
      
      final backupData = {
        'backup_date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'settings': settings,
        'projects': projects,
      };
      
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = path.join(
        directory.path,
        'backup_${DateTime.now().millisecondsSinceEpoch}.json'
      );
      
      final backupFile = File(backupPath);
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      await backupFile.writeAsString(jsonString);
      
      return backupPath;
    } catch (e) {
      print('خطأ في إنشاء النسخة الاحتياطية: $e');
      return null;
    }
  }

  /// استعادة من النسخة الاحتياطية
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        print('ملف النسخة الاحتياطية غير موجود');
        return false;
      }
      
      final backupContent = await backupFile.readAsString();
      final backupData = jsonDecode(backupContent);
      
      // استعادة الإعدادات
      if (backupData['settings'] != null) {
        await saveSettings(backupData['settings']);
      }
      
      // استعادة المشاريع
      if (backupData['projects'] != null) {
        final directory = await getApplicationDocumentsDirectory();
        final projectsDir = path.join(directory.path, 'Projects');
        
        for (final project in backupData['projects']) {
          final projectName = project['name'] ?? 'unnamed';
          final projectPath = path.join(projectsDir, '$projectName.json');
          final projectFile = File(projectPath);
          
          final projectJson = const JsonEncoder.withIndent('  ').convert(project);
          await projectFile.writeAsString(projectJson);
        }
      }
      
      return true;
    } catch (e) {
      print('خطأ في استعادة النسخة الاحتياطية: $e');
      return false;
    }
  }

  /// تنسيق حجم الملف
  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  /// التحقق من الصلاحيات
  Future<bool> checkDirectoryPermissions(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      
      // إنشاء المجلد إذا لم يكن موجوداً
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // اختبار الكتابة
      final testFile = File(path.join(directoryPath, '.permission_test'));
      await testFile.writeAsString('test');
      
      // اختبار القراءة
      final content = await testFile.readAsString();
      
      // حذف الملف التجريبي
      await testFile.delete();
      
      return content == 'test';
    } catch (e) {
      print('خطأ في التحقق من الصلاحيات: $e');
      return false;
    }
  }
}