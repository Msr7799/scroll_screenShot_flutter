// lib/services/screenshot_service.dart
// خدمة السكرين شوت الرئيسية - تدير عملية الالتقاط والسكرول

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

class ScreenshotService extends ChangeNotifier {
  final ScrollDetector _scrollDetector = ScrollDetector();
  final FileManager _fileManager = FileManager();
  
  bool _isCapturing = false;
  bool _isPaused = false;
  double _progress = 0.0;
  String _status = 'جاهز';
  List<CapturedImage> _capturedImages = [];
  ScreenshotConfig? _currentConfig;
  
  // Getters
  bool get isCapturing => _isCapturing;
  bool get isPaused => _isPaused;
  double get progress => _progress;
  String get status => _status;
  List<CapturedImage> get capturedImages => _capturedImages;
  ScreenshotConfig? get currentConfig => _currentConfig;

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

  /// تنفيذ عملية الالتقاط مع السكرول
  Future<void> _performScrollingCapture(ScreenshotConfig config) async {
    int sequenceNumber = 0;
    Uint8List? previousImage;
    
    while (_isCapturing) {
      // التحقق من الإيقاف المؤقت
      if (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      
      // التقاط الصورة الحالية
      final currentImage = await _captureScreenArea(config);
      if (currentImage == null) break;
      
      // إنشاء معرف فريد للصورة
      final capturedImage = CapturedImage(
        imageData: currentImage,
        timestamp: DateTime.now(),
        sequenceNumber: sequenceNumber++,
        hash: CapturedImage.calculateHash(currentImage),
      );
      
      _capturedImages.add(capturedImage);
      
      // تحديث التقدم
      _progress = (_capturedImages.length / 50).clamp(0.0, 1.0);
      _status = 'التقاط الصورة ${_capturedImages.length}...';
      notifyListeners();
      
      // اكتشاف السكرول
      if (previousImage != null) {
        final detection = await _scrollDetector.detectScrollChange(
          previousImage,
          currentImage,
        );
        
        if (detection.isAtEnd && config.autoDetectEnd) {
          _status = 'تم اكتشاف نهاية المحتوى';
          break;
        }
      }
      
      // تنفيذ السكرول
      await _performScroll(config);
      
      // تأخير قبل الالتقاط التالي
      await Future.delayed(Duration(milliseconds: config.scrollDelay));
      
      previousImage = currentImage;
    }
  }

  /// التقاط منطقة محددة من الشاشة
  Future<Uint8List?> _captureScreenArea(ScreenshotConfig config) async {
    try {
      // استخدام FFI للوصول إلى X11 في لينكس
      final result = await Process.run('import', [
        '-window', 'root',
        '-crop', '${config.width}x${config.height}+${config.x}+${config.y}',
        'png:-'
      ]);
      
      if (result.exitCode == 0) {
        return Uint8List.fromList(result.stdout);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في التقاط الشاشة: $e');
      return null;
    }
  }

  /// تنفيذ عملية السكرول
  Future<void> _performScroll(ScreenshotConfig config) async {
    try {
      // استخدام xdotool للسكرول في لينكس
      await Process.run('xdotool', [
        'mousemove', '${config.x + config.width ~/ 2}', '${config.y + config.height ~/ 2}',
        'click', '4', // سكرول للأسفل
        '--repeat', '3'
      ]);
    } catch (e) {
      debugPrint('خطأ في السكرول: $e');
    }
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

  /// دمج الصور الملتقطة في صورة واحدة
  Future<Uint8List?> mergeImages() async {
    if (_capturedImages.isEmpty) return null;
    
    _status = 'جاري دمج الصور...';
    notifyListeners();
    
    try {
      // فك تشفير الصورة الأولى لمعرفة الأبعاد
      final firstImage = img.decodeImage(_capturedImages.first.imageData);
      if (firstImage == null) return null;
      
      // إنشاء صورة جديدة بارتفاع مضاعف
      final mergedImage = img.Image(
        width: firstImage.width,
        height: firstImage.height * _capturedImages.length,
      );
      
      // دمج كل الصور
      for (int i = 0; i < _capturedImages.length; i++) {
        final currentImage = img.decodeImage(_capturedImages[i].imageData);
        if (currentImage != null) {
          img.compositeImage(
            mergedImage,
            currentImage,
            dstY: i * firstImage.height,
          );
        }
      }
      
      // تحويل إلى PNG
      final pngData = img.encodePng(mergedImage);
      return Uint8List.fromList(pngData);
      
    } catch (e) {
      debugPrint('خطأ في دمج الصور: $e');
      return null;
    }
  }

  /// حفظ الصورة المدمجة
  Future<String?> savemergedImage() async {
    final mergedData = await mergeImages();
    if (mergedData == null || _currentConfig == null) return null;
    
    return await _fileManager.saveImage(
      mergedData,
      _currentConfig!.outputPath,
      _currentConfig!.format,
    );
  }

  /// تنظيف الذاكرة
  void clearCapture() {
    _capturedImages.clear();
    _progress = 0.0;
    _status = 'جاهز';
    notifyListeners();
  }
}