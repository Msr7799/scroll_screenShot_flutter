// lib/utils/constants.dart
// الثوابت - تحتوي على القيم الثابتة المستخدمة في التطبيق

class AppConstants {
  // إعدادات التطبيق الافتراضية
  static const String appName = 'Professional Screenshot Tool';
  static const String appVersion = '1.0.0';
  
  // إعدادات السكرين شوت
  static const int defaultWidth = 800;
  static const int defaultHeight = 600;
  static const int defaultScrollDelay = 500;
  static const int defaultScrollStep = 100;
  static const double defaultQuality = 1.0;
  static const String defaultFormat = 'png';
  
  // حدود القيم
  static const int minWidth = 100;
  static const int maxWidth = 3840;
  static const int minHeight = 100;
  static const int maxHeight = 2160;
  static const int minScrollDelay = 100;
  static const int maxScrollDelay = 5000;
  
  // مسارات الملفات
  static const String defaultOutputPath = '/tmp/screenshots';
  static const String settingsFileName = 'settings.json';
  static const String projectsDirectoryName = 'Projects';
  
  // أنواع الملفات المدعومة
  static const List<String> supportedFormats = ['png', 'jpg', 'jpeg', 'bmp', 'tiff'];
  
  // رسائل الحالة
  static const String statusReady = 'جاهز';
  static const String statusCapturing = 'جاري الالتقاط...';
  static const String statusPaused = 'متوقف مؤقتاً';
  static const String statusStopped = 'تم الإيقاف';
  static const String statusCompleted = 'تم الانتهاء';
  static const String statusError = 'خطأ في العملية';
  
  // ألوان التطبيق
  static const primaryColor = 0xFF2196F3;
  static const secondaryColor = 0xFF03DAC6;
  static const errorColor = 0xFFB00020;
  static const successColor = 0xFF4CAF50;
  
  // أحجام الخطوط
  static const double titleFontSize = 20.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;
  
  // المسافات
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // أبعاد الويدجتس
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardElevation = 4.0;
  
  // مدة الرسوم المتحركة
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}

/// أسماء الصفحات للتنقل
class RouteNames {
  static const String home = '/';
  static const String preview = '/preview';
  static const String settings = '/settings';
  static const String about = '/about';
}

/// مفاتيح التخزين المحلي
class StorageKeys {
  static const String lastUsedConfig = 'last_used_config';
  static const String userPreferences = 'user_preferences';
  static const String recentProjects = 'recent_projects';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
}

/// أنواع الأخطاء
enum ErrorType {
  network,
  storage,
  permission,
  validation,
  system,
  unknown,
}

/// أنواع الإشعارات
enum NotificationType {
  success,
  warning,
  error,
  info,
}