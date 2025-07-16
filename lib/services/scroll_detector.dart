// lib/services/scroll_detector.dart
// كاشف السكرول - يحتوي على خوارزميات اكتشاف تغيير المحتوى

import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/scroll_detection.dart';

class ScrollDetector {
  static const double _similarityThreshold = 0.95;
  static const int _sampleSize = 50;
  
  /// اكتشاف تغيير المحتوى بين صورتين
  Future<ScrollDetection> detectScrollChange(
    Uint8List previousImage,
    Uint8List currentImage,
  ) async {
    try {
      // مقارنة الصور لاكتشاف التغيير
      final similarity = await _calculateImageSimilarity(previousImage, currentImage);
      
      // تحديد ما إذا كان هناك سكرول
      final hasScrolled = similarity < _similarityThreshold;
      
      // اكتشاف نهاية المحتوى
      final isAtEnd = await _detectEndOfContent(currentImage, previousImage);
      
      return ScrollDetection(
        previousImage: previousImage,
        currentImage: currentImage,
        hasScrolled: hasScrolled,
        similarity: similarity,
        scrollPosition: 0, // يمكن تطويره لحساب الموضع الفعلي
        isAtEnd: isAtEnd,
      );
    } catch (e) {
      return const ScrollDetection(
        hasScrolled: false,
        similarity: 0.0,
        scrollPosition: 0,
        isAtEnd: false,
      );
    }
  }

  /// حساب التشابه بين صورتين
  Future<double> _calculateImageSimilarity(
    Uint8List image1Data,
    Uint8List image2Data,
  ) async {
    try {
      final img1 = img.decodeImage(image1Data);
      final img2 = img.decodeImage(image2Data);
      
      if (img1 == null || img2 == null) return 0.0;
      
      // تقليل حجم الصور لتسريع المقارنة
      final resized1 = img.copyResize(img1, width: _sampleSize, height: _sampleSize);
      final resized2 = img.copyResize(img2, width: _sampleSize, height: _sampleSize);
      
      int totalPixels = _sampleSize * _sampleSize;
      int similarPixels = 0;
      
      // مقارنة البيكسلات
      for (int y = 0; y < _sampleSize; y++) {
        for (int x = 0; x < _sampleSize; x++) {
          final pixel1 = resized1.getPixel(x, y);
          final pixel2 = resized2.getPixel(x, y);
          
          if (_arePixelsSimilar(pixel1, pixel2)) {
            similarPixels++;
          }
        }
      }
      
      return similarPixels / totalPixels;
    } catch (e) {
      return 0.0;
    }
  }

  /// التحقق من تشابه البيكسلات
  bool _arePixelsSimilar(img.Pixel pixel1, img.Pixel pixel2) {
    const int tolerance = 10;
    
    return (pixel1.r - pixel2.r).abs() < tolerance &&
           (pixel1.g - pixel2.g).abs() < tolerance &&
           (pixel1.b - pixel2.b).abs() < tolerance;
  }

  /// اكتشاف نهاية المحتوى
  Future<bool> _detectEndOfContent(
    Uint8List currentImage,
    Uint8List previousImage,
  ) async {
    try {
      // فحص الجزء السفلي من الصورة للتحقق من تكرار المحتوى
      final current = img.decodeImage(currentImage);
      final previous = img.decodeImage(previousImage);
      
      if (current == null || previous == null) return false;
      
      // فحص الـ 20% السفلية من الصورة
      final bottomHeight = (current.height * 0.2).round();
      final bottomRegionCurrent = img.copyCrop(
        current,
        x: 0,
        y: current.height - bottomHeight,
        width: current.width,
        height: bottomHeight,
      );
      
      final bottomRegionPrevious = img.copyCrop(
        previous,
        x: 0,
        y: previous.height - bottomHeight,
        width: previous.width,
        height: bottomHeight,
      );
      
      // حساب التشابه للمنطقة السفلية
      final bottomSimilarity = await _calculateRegionSimilarity(
        bottomRegionCurrent,
        bottomRegionPrevious,
      );
      
      // إذا كان التشابه عالي في المنطقة السفلية، فربما وصلنا للنهاية
      return bottomSimilarity > 0.98;
    } catch (e) {
      return false;
    }
  }

  /// حساب التشابه لمنطقة محددة
  Future<double> _calculateRegionSimilarity(
    img.Image region1,
    img.Image region2,
  ) async {
    if (region1.width != region2.width || region1.height != region2.height) {
      return 0.0;
    }
    
    int totalPixels = region1.width * region1.height;
    int similarPixels = 0;
    
    for (int y = 0; y < region1.height; y++) {
      for (int x = 0; x < region1.width; x++) {
        final pixel1 = region1.getPixel(x, y);
        final pixel2 = region2.getPixel(x, y);
        
        if (_arePixelsSimilar(pixel1, pixel2)) {
          similarPixels++;
        }
      }
    }
    
    return similarPixels / totalPixels;
  }

  /// اكتشاف اتجاه السكرول
  Future<ScrollDirection> detectScrollDirection(
    Uint8List image1,
    Uint8List image2,
  ) async {
    // يمكن تطوير هذه الدالة لاكتشاف اتجاه السكرول
    return ScrollDirection.down;
  }
}

/// اتجاهات السكرول المختلفة
enum ScrollDirection {
  up,
  down,
  left,
  right,
  none,
}