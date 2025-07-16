// lib/models/scroll_detection.dart
// نموذج اكتشاف السكرول - يحتوي على معلومات حالة السكرول والمقارنة

import 'dart:typed_data';

class ScrollDetection {
  final Uint8List? previousImage;
  final Uint8List? currentImage;
  final bool hasScrolled;
  final double similarity;
  final int scrollPosition;
  final bool isAtEnd;
  
  const ScrollDetection({
    this.previousImage,
    this.currentImage,
    required this.hasScrolled,
    required this.similarity,
    required this.scrollPosition,
    required this.isAtEnd,
  });

  /// إنشاء نسخة معدلة من حالة السكرول
  ScrollDetection copyWith({
    Uint8List? previousImage,
    Uint8List? currentImage,
    bool? hasScrolled,
    double? similarity,
    int? scrollPosition,
    bool? isAtEnd,
  }) {
    return ScrollDetection(
      previousImage: previousImage ?? this.previousImage,
      currentImage: currentImage ?? this.currentImage,
      hasScrolled: hasScrolled ?? this.hasScrolled,
      similarity: similarity ?? this.similarity,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isAtEnd: isAtEnd ?? this.isAtEnd,
    );
  }
}

/// نموذج لتخزين معلومات الصورة الملتقطة
class CapturedImage {
  final Uint8List imageData;
  final DateTime timestamp;
  final int sequenceNumber;
  final String hash;
  
  const CapturedImage({
    required this.imageData,
    required this.timestamp,
    required this.sequenceNumber,
    required this.hash,
  });

  /// حساب الهاش للصورة
  static String calculateHash(Uint8List data) {
    return data.hashCode.toString();
  }
}