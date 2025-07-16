// lib/utils/helpers.dart
// دوال مساعدة - تحتوي على دوال مفيدة للتطبيق

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'constants.dart';

class AppHelpers {
  
  /// التحقق من صحة أبعاد الصورة
  static bool validateDimensions(int width, int height) {
    return width >= AppConstants.minWidth &&
           width <= AppConstants.maxWidth &&
           height >= AppConstants.minHeight &&
           height <= AppConstants.maxHeight;
  }

  /// تنسيق حجم الملف
  static String formatFileSize(int bytes) {
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

  /// تنسيق المدة الزمنية
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }

  /// إنشاء اسم ملف فريد
  static String generateUniqueFileName(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(1000);
    return '${prefix}_${timestamp}_$random.$extension';
  }

  /// التحقق من وجود أدوات النظام المطلوبة
  static Future<SystemCheckResult> checkSystemRequirements() async {
    final result = SystemCheckResult();
    
    try {
      // التحقق من imagemagick
      final importResult = await Process.run('which', ['import']);
      result.hasImageMagick = importResult.exitCode == 0;
      
      // التحقق من xdotool
      final xdotoolResult = await Process.run('which', ['xdotool']);
      result.hasXdotool = xdotoolResult.exitCode == 0;
      
      // التحقق من X11
      final x11Result = await Process.run('echo', ['\$DISPLAY']);
      result.hasX11 = x11Result.stdout.toString().trim().isNotEmpty;
      
    } catch (e) {
      result.error = e.toString();
    }
    
    return result;
  }

  /// حساب نسبة العرض إلى الارتفاع
  static AspectRatio calculateAspectRatio(int width, int height) {
    if (height == 0) return AspectRatio(width, 1);
    
    final gcd = _gcd(width, height);
    return AspectRatio(width ~/ gcd, height ~/ gcd);
  }

  /// حساب القاسم المشترك الأكبر
  static int _gcd(int a, int b) {
    while (b != 0) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  /// ضغط الصورة
  static Future<Uint8List?> compressImage(
    Uint8List imageData,
    double quality,
    {int? maxWidth, int? maxHeight}
  ) async {
    try {
      final originalImage = img.decodeImage(imageData);
      if (originalImage == null) return null;
      
      img.Image processedImage = originalImage;
      
      // تغيير الحجم إذا لزم الأمر
      if (maxWidth != null || maxHeight != null) {
        processedImage = img.copyResize(
          originalImage,
          width: maxWidth,
          height: maxHeight,
        );
      }
      
      // ضغط الصورة
      final compressedData = img.encodeJpg(
        processedImage,
        quality: (quality * 100).round(),
      );
      
      return Uint8List.fromList(compressedData);
    } catch (e) {
      debugPrint('خطأ في ضغط الصورة: $e');
      return null;
    }
  }

  /// دمج عدة صور في صورة واحدة
  static Future<Uint8List?> mergeImagesVertically(
    List<Uint8List> images,
    {int? maxWidth}
  ) async {
    try {
      if (images.isEmpty) return null;
      
      final decodedImages = <img.Image>[];
      int totalHeight = 0;
      int maxImageWidth = 0;
      
      // فك تشفير الصور وحساب الأبعاد
      for (final imageData in images) {
        final decoded = img.decodeImage(imageData);
        if (decoded != null) {
          decodedImages.add(decoded);
          totalHeight += decoded.height;
          maxImageWidth = math.max(maxImageWidth, decoded.width);
        }
      }
      
      if (decodedImages.isEmpty) return null;
      
      // تحديد العرض النهائي
      final finalWidth = maxWidth ?? maxImageWidth;
      
      // إنشاء الصورة المدمجة
      final mergedImage = img.Image(
        width: finalWidth,
        height: totalHeight,
      );
      
      // دمج الصور
      int currentY = 0;
      for (final image in decodedImages) {
        final resizedImage = img.copyResize(image, width: finalWidth);
        img.compositeImage(mergedImage, resizedImage, dstY: currentY);
        currentY += resizedImage.height;
      }
      
      // تحويل إلى PNG
      final pngData = img.encodePng(mergedImage);
      return Uint8List.fromList(pngData);
      
    } catch (e) {
      debugPrint('خطأ في دمج الصور: $e');
      return null;
    }
  }

  /// إضافة علامة مائية للصورة
  static Future<Uint8List?> addWatermark(
    Uint8List imageData,
    String text, {
      Color color = Colors.white,
      double opacity = 0.7,
      WatermarkPosition position = WatermarkPosition.bottomRight,
    }
  ) async {
    try {
      final originalImage = img.decodeImage(imageData);
      if (originalImage == null) return null;

      // إنشاء نسخة من الصورة الأصلية
      final watermarkedImage = img.Image.from(originalImage);

      // ملاحظة: يجب عليك هنا كتابة كود رسم النص على الصورة باستخدام مكتبة image
      // الكود الحالي غير مكتمل ويجب استكماله حسب الحاجة

      // مثال: فقط إعادة الصورة الأصلية بدون تعديل
      return Uint8List.fromList(img.encodePng(watermarkedImage));
    } catch (e) {
      debugPrint('خطأ في إضافة العلامة المائية: $e');
      return null;
    }
  }

  /// الحصول على مسار مجلد الصور الافتراضي
  static Future<String> getDefaultPicturesPath() async {
    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final picturesPath = path.join(homeDir, 'Pictures', 'Screenshots');
        final directory = Directory(picturesPath);
        
        // إنشاء المجلد إذا لم يكن موجوداً
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        return picturesPath;
      }
      
      // مسار احتياطي
      return '/tmp/screenshots';
    } catch (e) {
      return '/tmp/screenshots';
    }
  }

  /// التحقق من صحة المسار
  static Future<bool> isValidPath(String pathString) async {
    try {
      final directory = Directory(pathString);
      
      // التحقق من وجود المجلد
      if (await directory.exists()) {
        return true;
      }
      
      // محاولة إنشاء المجلد
      try {
        await directory.create(recursive: true);
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// اقتراح مسارات شائعة
  static List<String> getSuggestedPaths() {
    final homeDir = Platform.environment['HOME'] ?? '/home/user';
    
    return [
      path.join(homeDir, 'Pictures'),
      path.join(homeDir, 'Pictures', 'Screenshots'),
      path.join(homeDir, 'Desktop'),
      path.join(homeDir, 'Downloads'),
      path.join(homeDir, 'Documents'),
      '/tmp/screenshots',
    ];
  }

  /// فتح مدير الملفات في المسار المحدد
  static Future<bool> openFileManager(String directoryPath) async {
    try {
      // محاولة فتح مدير الملفات الافتراضي
      final result = await Process.run('xdg-open', [directoryPath]);
      return result.exitCode == 0;
    } catch (e) {
      try {
        // محاولة بديلة مع nautilus
        final result = await Process.run('nautilus', [directoryPath]);
        return result.exitCode == 0;
      } catch (e) {
        try {
          // محاولة أخيرة مع dolphin
          final result = await Process.run('dolphin', [directoryPath]);
          return result.exitCode == 0;
        } catch (e) {
          return false;
        }
      }
    }
  }

  /// الحصول على معلومات المجلد
  static Future<Map<String, dynamic>> getDirectoryInfo(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      
      if (!await directory.exists()) {
        return {
          'exists': false,
          'readable': false,
          'writable': false,
          'fileCount': 0,
        };
      }
      
      // عدد الملفات
      int fileCount = 0;
      try {
        await for (final entity in directory.list()) {
          if (entity is File) {
            fileCount++;
          }
        }
      } catch (e) {
        // لا يمكن قراءة المجلد
      }
      
      // اختبار الكتابة
      bool writable = false;
      try {
        final testFile = File(path.join(directoryPath, '.test_write'));
        await testFile.writeAsString('test');
        await testFile.delete();
        writable = true;
      } catch (e) {
        writable = false;
      }
      
      return {
        'exists': true,
        'readable': true,
        'writable': writable,
        'fileCount': fileCount,
      };
    } catch (e) {
      return {
        'exists': false,
        'readable': false,
        'writable': false,
        'fileCount': 0,
        'error': e.toString(),
      };
    }
  }
}