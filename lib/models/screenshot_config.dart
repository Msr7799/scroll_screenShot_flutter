// lib/models/screenshot_config.dart
// نموذج إعدادات السكرين شوت - يحتوي على جميع الخصائص المطلوبة للالتقاط

class ScreenshotConfig {
  final int x;
  final int y;
  final int width;
  final int height;
  final double quality;
  final String format;
  final bool includeScrolling;
  final int scrollDelay;
  final int scrollStep;
  final bool autoDetectEnd;
  final String outputPath;
  
  const ScreenshotConfig({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.quality = 1.0,
    this.format = 'png',
    this.includeScrolling = true,
    this.scrollDelay = 500,
    this.scrollStep = 100,
    this.autoDetectEnd = true,
    required this.outputPath,
  });

  /// إنشاء نسخة معدلة من الإعدادات
  ScreenshotConfig copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
    double? quality,
    String? format,
    bool? includeScrolling,
    int? scrollDelay,
    int? scrollStep,
    bool? autoDetectEnd,
    String? outputPath,
  }) {
    return ScreenshotConfig(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      quality: quality ?? this.quality,
      format: format ?? this.format,
      includeScrolling: includeScrolling ?? this.includeScrolling,
      scrollDelay: scrollDelay ?? this.scrollDelay,
      scrollStep: scrollStep ?? this.scrollStep,
      autoDetectEnd: autoDetectEnd ?? this.autoDetectEnd,
      outputPath: outputPath ?? this.outputPath,
    );
  }

  /// تحويل إلى Map للحفظ
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'quality': quality,
      'format': format,
      'includeScrolling': includeScrolling,
      'scrollDelay': scrollDelay,
      'scrollStep': scrollStep,
      'autoDetectEnd': autoDetectEnd,
      'outputPath': outputPath,
    };
  }

  /// إنشاء من Map
  factory ScreenshotConfig.fromMap(Map<String, dynamic> map) {
    return ScreenshotConfig(
      x: map['x'] ?? 0,
      y: map['y'] ?? 0,
      width: map['width'] ?? 800,
      height: map['height'] ?? 600,
      quality: map['quality'] ?? 1.0,
      format: map['format'] ?? 'png',
      includeScrolling: map['includeScrolling'] ?? true,
      scrollDelay: map['scrollDelay'] ?? 500,
      scrollStep: map['scrollStep'] ?? 100,
      autoDetectEnd: map['autoDetectEnd'] ?? true,
      outputPath: map['outputPath'] ?? '',
    );
  }
}