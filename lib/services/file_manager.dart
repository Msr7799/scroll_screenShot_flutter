// lib/services/file_manager.dart
// مدير الملفات - يتعامل مع حفظ وتصدير الصور

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
      
      // التأكد من وجود المجلد
      final directory = Directory(path.dirname(finalPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // حفظ الملف
      final file = File(finalPath);
      await file.writeAsBytes(imageData);
      
      return finalPath;
    } catch (e) {
      print('خطأ في حفظ الصورة: $e');
      return null;
    }
  }

  /// الحصول على مجلد الصور الافتراضي
  Future<String> getDefaultPicturesDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final screenshotsDir = path.join(directory.path, 'Screenshots');
      
      // إنشاء المجلد إذا لم يكن موجوداً
      final dir = Directory(screenshotsDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      return screenshotsDir;
    } catch (e) {
      return '/tmp/screenshots';
    }
  }

  /// حفظ إعدادات التطبيق
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final settingsFile = File(path.join(directory.path, 'settings.json'));
      
      final jsonString = jsonEncode(settings);
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
        'created': DateTime.now().toIso8601String(),
        'screenshots': [],
        'settings': {},
      };
      
      await projectFile.writeAsString(jsonEncode(projectData));
      return projectFile.path;
    } catch (e) {
      print('خطأ في إنشاء ملف المشروع: $e');
      return null;
    }
  }
}