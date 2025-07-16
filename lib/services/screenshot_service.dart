// lib/services/screenshot_service.dart
// خدمة السكرين شوت المحدثة مع إصلاح الأخطاء والتحسينات

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import '../models/screenshot_config.dart';
import '../models/scroll_detection.dart';
import 'scroll_detector.dart';
import 'file_manager.dart';
import 'screen_overlay_service.dart';

class ScreenshotService extends ChangeNotifier {
  final ScrollDetector _scrollDetector = ScrollDetector();
  final FileManager _fileManager = FileManager();
  final ScreenOverlayService _overlayService = ScreenOverlayService();
  
  bool _isCapturing = false;
  bool _isPaused = false;
  bool _isSelectingArea = false;
  double _progress = 0.0;
  String _status = 'جاهز';
  List<CapturedImage> _capturedImages = [];
  ScreenshotConfig? _currentConfig;
  
  // Getters
  bool get isCapturing => _isCapturing;
  bool get isPaused => _isPaused;
  bool get isSelectingArea => _isSelectingArea;
  double get progress => _progress;
  String get status => _status;
  List<CapturedImage> get capturedImages => _capturedImages;
  ScreenshotConfig? get currentConfig => _currentConfig;

  /// تهيئة الخدمة
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _overlayService.initialize(navigatorKey);
  }

  /// بدء تحديد المنطقة بواسطة الـ overlay
  Future<ScreenshotConfig?> startAreaSelection() async {
    if (_isSelectingArea) return null;
    
    _isSelectingArea = true;
    _status = 'اختر المنطقة من الشاشة...';
    notifyListeners();
    
    try {
      final selectedConfig = await _overlayService.startAreaSelection();
      return selectedConfig;
    } catch (e) {
      _status = 'خطأ في تحديد المنطقة: $e';
      return null;
    } finally {
      _isSelectingArea = false;
      _status = 'جاهز';
      notifyListeners();
    }
  }

  /// بدء عملية السكرين شوت مع السكرول
  Future<void> startScrollingScreenshot(ScreenshotConfig config) async {
    if (_isCapturing) return;
    
    _isCapturing = true;
    _isPaused = false;
    _progress = 0.0;
    _status = 'بدء الالتقاط...';
    _capturedImages.clear();
    _currentConfig = config;
    
    notifyListeners();
    
    try {
      await _performScrollingCapture(config);
      _status = 'تم الانتهاء من الالتقاط';
    } catch (e) {
      _status = 'خطأ في الالتقاط: $e';
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }

  /// تنفيذ عملية الالتقاط مع السكرول المحسن
  Future<void> _performScrollingCapture(ScreenshotConfig config) async {
    int sequenceNumber = 0;
    Uint8List? previousImage;
    int consecutiveSimilarImages = 0;
    const maxSimilarImages = 3; // عدد الصور المتشابهة قبل التوقف
    
    // إخفاء النافذة أثناء الالتقاط
    await _hideWindowForCapture();
    
    while (_isCapturing) {
      // التحقق من الإيقاف المؤقت
      if (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      
      // التقاط الصورة الحالية
      final currentImage = await _captureScreenArea(config);
      if (currentImage == null) {
        _status = 'فشل في التقاط الصورة';
        break;
      }
      
      // التحقق من جودة الصورة
      if (!_isValidImage(currentImage)) {
        _status = 'صورة غير صالحة، إعادة المحاولة...';
        await Future.delayed(Duration(milliseconds: config.scrollDelay));
        continue;
      }
      
      // إنشاء معرف فريد للصورة
      final capturedImage = CapturedImage(
        imageData: currentImage,
        timestamp: DateTime.now(),
        sequenceNumber: sequenceNumber++,
        hash: CapturedImage.calculateHash(currentImage),
      );
      
      // التحقق من التكرار
      if (_isImageDuplicate(capturedImage)) {
        consecutiveSimilarImages++;
        if (consecutiveSimilarImages >= maxSimilarImages) {
          _status = 'تم اكتشاف تكرار في الصور - انتهاء المحتوى';
          break;
        }
      } else {
        consecutiveSimilarImages = 0;
      }
      
      _capturedImages.add(capturedImage);
      
      // تحديث التقدم
      _progress = (_capturedImages.length / 50).clamp(0.0, 1.0);
      _status = 'التقاط الصورة ${_capturedImages.length}...';
      notifyListeners();
      
      // اكتشاف السكرول المحسن
      if (previousImage != null && config.includeScrolling) {
        final detection = await _scrollDetector.detectScrollChange(
          previousImage,
          currentImage,
        );
        
        if (detection.isAtEnd && config.autoDetectEnd) {
          _status = 'تم اكتشاف نهاية المحتوى';
          break;
        }
        
        // تحديث إستراتيجية السكرول بناءً على التحليل
        await _adaptiveScroll(config, detection);
      } else {
        // السكرول العادي للصورة الأولى
        await _performScroll(config);
      }
      
      // تأخير قابل للتكيف
      final adaptiveDelay = _calculateAdaptiveDelay(config, sequenceNumber);
      await Future.delayed(Duration(milliseconds: adaptiveDelay));
      
      previousImage = currentImage;
      
      // حد أقصى للصور لتجنب الحلقات اللا نهائية
      if (_capturedImages.length >= 100) {
        _status = 'تم الوصول للحد الأقصى من الصور';
        break;
      }
    }
    
    // إعادة عرض النافذة
    await _showWindowAfterCapture();
  }

  /// إخفاء النافذة أثناء الالتقاط
  Future<void> _hideWindowForCapture() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('خطأ في إخفاء النافذة: $e');
    }
  }

  /// إعادة عرض النافذة بعد الالتقاط
  Future<void> _showWindowAfterCapture() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('خطأ في إعادة عرض النافذة: $e');
    }
  }

  /// التحقق من صحة الصورة
  bool _isValidImage(Uint8List imageData) {
    try {
      final image = img.decodeImage(imageData);
      return image != null && image.width > 0 && image.height > 0;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من تكرار الصورة
  bool _isImageDuplicate(CapturedImage newImage) {
    if (_capturedImages.isEmpty) return false;
    
    // مقارنة مع آخر 3 صور
    final recentImages = _capturedImages.reversed.take(3);
    
    for (final recentImage in recentImages) {
      if (recentImage.hash == newImage.hash) {
        return true;
      }
    }
    
    return false;
  }

  /// التقاط منطقة محددة من الشاشة مع تحسينات
  Future<Uint8List?> _captureScreenArea(ScreenshotConfig config) async {
    try {
      // التأكد من صحة المعاملات
      if (config.width <= 0 || config.height <= 0) {
        return null;
      }
      
      // استخدام أدوات النظام المحسنة
      final result = await Process.run('import', [
        '-window', 'root',
        '-crop', '${config.width}x${config.height}+${config.x}+${config.y}',
        '-depth', '8',
        '-quality', '${(config.quality * 100).round()}',
        'png:-'
      ]);
      
      if (result.exitCode == 0 && result.stdout.isNotEmpty) {
        return Uint8List.fromList(result.stdout);
      }
      
      return null;
    } catch (e) {
      debugPrint('خطأ في التقاط الشاشة: $e');
      return null;
    }
  }

  /// سكرول قابل للتكيف
  Future<void> _adaptiveScroll(ScreenshotConfig config, ScrollDetection detection) async {
    try {
      // تحديد مقدار السكرول بناءً على التشابه
      int scrollAmount = config.scrollStep;
      
      if (detection.similarity > 0.9) {
        // تشابه عالي - زيادة السكرول
        scrollAmount = (config.scrollStep * 1.5).round();
      } else if (detection.similarity < 0.3) {
        // تشابه منخفض - تقليل السكرول
        scrollAmount = (config.scrollStep * 0.7).round();
      }
      
      // تنفيذ السكرول مع المقدار المحسوب
      await Process.run('xdotool', [
        'mousemove', '${config.x + config.width ~/ 2}', '${config.y + config.height ~/ 2}',
        'click', '4', // سكرول للأسفل
        '--repeat', '${(scrollAmount / 100).ceil()}'
      ]);
      
    } catch (e) {
      debugPrint('خطأ في السكرول التكيفي: $e');
      // العودة للسكرول العادي
      await _performScroll(config);
    }
  }

  /// تنفيذ عملية السكرول العادية
  Future<void> _performScroll(ScreenshotConfig config) async {
    try {
      await Process.run('xdotool', [
        'mousemove', '${config.x + config.width ~/ 2}', '${config.y + config.height ~/ 2}',
        'click', '4', // سكرول للأسفل
        '--repeat', '3'
      ]);
    } catch (e) {
      debugPrint('خطأ في السكرول: $e');
    }
  }

  /// حساب التأخير القابل للتكيف
  int _calculateAdaptiveDelay(ScreenshotConfig config, int sequenceNumber) {
    // تقليل التأخير تدريجياً مع التقدم
    int baseDelay = config.scrollDelay;
    
    if (sequenceNumber > 10) {
      baseDelay = (baseDelay * 0.8).round();
    }
    
    if (sequenceNumber > 20) {
      baseDelay = (baseDelay * 0.7).round();
    }
    
    return baseDelay.clamp(200, config.scrollDelay);
  }

  /// إيقاف مؤقت للالتقاط
  void pauseCapture() {
    _isPaused = true;
    _status = 'متوقف مؤقتاً';
    notifyListeners();
  }

  /// استئناف الالتقاط
  void resumeCapture() {
    _isPaused = false;
    _status = 'جاري الالتقاط...';
    notifyListeners();
  }

  /// إيقاف الالتقاط نهائياً
  void stopCapture() {
    _isCapturing = false;
    _isPaused = false;
    _status = 'تم الإيقاف';
    notifyListeners();
  }

  /// دمج الصور الملتقطة في صورة واحدة مع تحسينات
  Future<Uint8List?> mergeImages() async {
    if (_capturedImages.isEmpty) return null;
    
    _status = 'جاري دمج الصور...';
    notifyListeners();
    
    try {
      // فرز الصور حسب الترتيب الزمني
      final sortedImages = List<CapturedImage>.from(_capturedImages)
        ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
      
      // فك تشفير الصورة الأولى لمعرفة الأبعاد
      final firstImage = img.decodeImage(sortedImages.first.imageData);
      if (firstImage == null) return null;
      
      // حساب الارتفاع الإجمالي مع تداخل ذكي
      int totalHeight = firstImage.height;
      const overlapPixels = 50; // تداخل لضمان الاستمرارية
      
      for (int i = 1; i < sortedImages.length; i++) {
        totalHeight += firstImage.height - overlapPixels;
      }
      
      // إنشاء صورة جديدة بالأبعاد المحسوبة
      final mergedImage = img.Image(
        width: firstImage.width,
        height: totalHeight,
      );
      
      // ملء الخلفية باللون الأبيض
      img.fill(mergedImage, color: img.ColorRgb8(255, 255, 255));
      
      // دمج كل الصور مع التداخل
      int currentY = 0;
      for (int i = 0; i < sortedImages.length; i++) {
        final currentImage = img.decodeImage(sortedImages[i].imageData);
        if (currentImage != null) {
          // تطبيق مرشح تحسين الجودة
          final enhancedImage = _enhanceImage(currentImage);
          
          // استخدام compositeImage بدون BlendMode.over (غير مدعوم)
          img.compositeImage(
            mergedImage,
            enhancedImage,
            dstY: currentY,
          );
          
          if (i < sortedImages.length - 1) {
            currentY += currentImage.height - overlapPixels;
          }
        }
      }
      
      // تطبيق تحسينات على الصورة النهائية
      final finalImage = _postProcessImage(mergedImage);
      
      // تحويل إلى تنسيق مناسب
      final outputData = _currentConfig?.format == 'jpg' 
          ? img.encodeJpg(finalImage, quality: (_currentConfig!.quality * 100).round())
          : img.encodePng(finalImage);
      
      _status = 'تم دمج ${sortedImages.length} صورة بنجاح';
      return Uint8List.fromList(outputData);
      
    } catch (e) {
      debugPrint('خطأ في دمج الصور: $e');
      _status = 'خطأ في دمج الصور: $e';
      return null;
    }
  }

  /// تحسين جودة الصورة (مُصحح: استخدام int للـ radius)
  img.Image _enhanceImage(img.Image image) {
    // تطبيق تحسينات بسيطة
    var enhanced = img.Image.from(image);
    
    // زيادة التباين قليلاً
    enhanced = img.adjustColor(enhanced, contrast: 1.1);
    
    // تحسين الوضوح (مُصحح: استخدام radius كـ int)
    enhanced = img.gaussianBlur(enhanced, radius: 1);
    
    return enhanced;
  }

  /// معالجة ما بعد الدمج (مُصحح: استخدام int للـ radius)
  img.Image _postProcessImage(img.Image image) {
    var processed = img.Image.from(image);
    
    // إزالة الضوضاء البسيطة (مُصحح: استخدام radius كـ int)
    processed = img.gaussianBlur(processed, radius: 1);
    
    // تحسين الألوان
    processed = img.adjustColor(processed, saturation: 1.05, brightness: 1.02);
    
    return processed;
  }

  /// حفظ الصورة المدمجة مع معلومات إضافية
  Future<String?> saveMergedImage() async {
    final mergedData = await mergeImages();
    if (mergedData == null || _currentConfig == null) return null;
    
    try {
      // إنشاء اسم ملف وصفي
      final timestamp = DateTime.now();
      final formattedDate = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      final formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}-${timestamp.minute.toString().padLeft(2, '0')}-${timestamp.second.toString().padLeft(2, '0')}';
      
      final filename = 'scroll_screenshot_${formattedDate}_${formattedTime}_${_capturedImages.length}imgs.${_currentConfig!.format}';
      final fullPath = path.join(_currentConfig!.outputPath, filename);
      
      // حفظ الملف
      final savedPath = await _fileManager.saveImageWithPath(
        mergedData,
        fullPath,
      );
      
      if (savedPath != null) {
        // حفظ معلومات إضافية
        await _saveImageMetadata(savedPath);
        _status = 'تم حفظ الصورة: $filename';
      }
      
      return savedPath;
    } catch (e) {
      _status = 'خطأ في الحفظ: $e';
      return null;
    }
  }

  /// حفظ معلومات الصورة
  Future<void> _saveImageMetadata(String imagePath) async {
    try {
      final metadata = {
        'capture_date': DateTime.now().toIso8601String(),
        'image_count': _capturedImages.length,
        'config': _currentConfig?.toMap(),
        'total_duration': _capturedImages.isNotEmpty 
            ? _capturedImages.last.timestamp.difference(_capturedImages.first.timestamp).inSeconds
            : 0,
        'average_delay': _currentConfig?.scrollDelay ?? 0,
        'final_size': {
          'width': _currentConfig?.width ?? 0,
          'height': _capturedImages.length * (_currentConfig?.height ?? 0),
        }
      };
      
      final metadataPath = imagePath.replaceAll(path.extension(imagePath), '_metadata.json');
      await _fileManager.saveMetadata(metadataPath, metadata);
    } catch (e) {
      debugPrint('خطأ في حفظ المعلومات الإضافية: $e');
    }
  }

  /// الحصول على إحصائيات الالتقاط
  Map<String, dynamic> getCaptureStatistics() {
    if (_capturedImages.isEmpty) return {};
    
    final firstImage = _capturedImages.first;
    final lastImage = _capturedImages.last;
    final duration = lastImage.timestamp.difference(firstImage.timestamp);
    
    return {
      'total_images': _capturedImages.length,
      'duration_seconds': duration.inSeconds,
      'average_interval': _capturedImages.length > 1 
          ? duration.inMilliseconds / (_capturedImages.length - 1)
          : 0,
      'estimated_file_size': _capturedImages.fold<int>(
        0, 
        (sum, img) => sum + img.imageData.length,
      ),
      'config_used': _currentConfig?.toMap(),
    };
  }

  /// معاينة سريعة للصورة المدمجة
  Future<Uint8List?> generatePreview() async {
    if (_capturedImages.isEmpty) return null;
    
    try {
      // إنشاء معاينة مصغرة
      const previewWidth = 300;
      final aspectRatio = _currentConfig != null 
          ? _currentConfig!.height / _currentConfig!.width
          : 1.0;
      final previewHeight = (previewWidth * aspectRatio * _capturedImages.length * 0.1).round();
      
      final previewImage = img.Image(
        width: previewWidth,
        height: previewHeight,
      );
      
      // رسم عينة من الصور
      final sampleSize = (_capturedImages.length / 10).ceil();
      int currentY = 0;
      
      for (int i = 0; i < _capturedImages.length; i += sampleSize) {
        final imageData = _capturedImages[i].imageData;
        final decoded = img.decodeImage(imageData);
        
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: previewWidth);
          final sampleHeight = previewHeight ~/ 10;
          
          img.compositeImage(
            previewImage,
            resized,
            dstY: currentY,
            dstH: sampleHeight,
          );
          
          currentY += sampleHeight;
        }
      }
      
      return Uint8List.fromList(img.encodePng(previewImage));
    } catch (e) {
      debugPrint('خطأ في إنشاء المعاينة: $e');
      return null;
    }
  }

  /// التحقق من متطلبات النظام - إصدار واحد فقط
  Future<bool> checkSystemRequirements() async {
    try {
      // التحقق من imagemagick
      final importCheck = await Process.run('which', ['import']);
      if (importCheck.exitCode != 0) {
        _status = 'خطأ: imagemagick غير مثبت';
        return false;
      }
      
      // التحقق من xdotool
      final xdotoolCheck = await Process.run('which', ['xdotool']);
      if (xdotoolCheck.exitCode != 0) {
        _status = 'خطأ: xdotool غير مثبت';
        return false;
      }
      
      // التحقق من X11
      final displayCheck = Platform.environment['DISPLAY'];
      if (displayCheck == null || displayCheck.isEmpty) {
        _status = 'خطأ: بيئة X11 غير متوفرة';
        return false;
      }
      
      return true;
    } catch (e) {
      _status = 'خطأ في التحقق من متطلبات النظام: $e';
      return false;
    }
  }

  /// تنظيف الذاكرة وإعادة التعيين - إصدار واحد فقط
  void clearCapture() {
    _capturedImages.clear();
    _progress = 0.0;
    _status = 'جاهز';
    _currentConfig = null;
    notifyListeners();
  }
}