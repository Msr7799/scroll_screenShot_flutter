// lib/main.dart
// الملف الرئيسي المحدث مع النظام الجديد

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/screens/home_screen.dart';
import 'services/screenshot_service.dart';
import 'services/screen_overlay_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة مدير النافذة للينكس
  await windowManager.ensureInitialized();
  
  // إعداد النافذة
  await _setupWindow();
  
  runApp(const MyApp());
}

/// إعداد خصائص النافذة الأساسية
Future<void> _setupWindow() async {
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(900, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Professional Screenshot Tool - أداة السكرين شوت الاحترافية',
    // إضافة إعدادات جديدة للنظام المحدث
    alwaysOnTop: false,
    fullScreen: false,
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    
    // تعيين الحد الأدنى والأقصى لحجم النافذة
    await windowManager.setMinimumSize(const Size(900, 700));
    await windowManager.setMaximumSize(const Size(1920, 1080));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // خدمة السكرين شوت الأساسية
        ChangeNotifierProvider(create: (_) => ScreenshotService()),
        
        // يمكن إضافة خدمات أخرى هنا
        Provider<ScreenOverlayService>(
          create: (_) => ScreenOverlayService(),
        ),
      ],
      child: MaterialApp(
        title: 'Professional Screenshot Tool',
        debugShowCheckedModeBanner: false,
        
        // إعداد الثيم
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        
        // الشاشة الرئيسية
        home: const HomeScreen(),
        
        // إعدادات إضافية
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // منع تغيير حجم النص من النظام
            ),
            child: child!,
          );
        },
      ),
    );
  }

  /// بناء الثيم الفاتح
  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFF2196F3);
    const secondaryColor = Color(0xFF03DAC6);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      
      // خطوط مخصصة للعربية
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF424242),
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: Color(0xFF424242),
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Color(0xFF757575),
        ),
      ),
      
      // إعدادات الكروت
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Colors.white,
      ),
      
      // إعدادات الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // إعدادات حقول النص
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // شريط التطبيق
      appBarTheme: const AppBarTheme(
        elevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // الأيقونات
      iconTheme: const IconThemeData(
        color: Color(0xFF757575),
        size: 24,
      ),
      
      // الفواصل
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
    );
  }

  /// بناء الثيم الداكن
  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFF64B5F6);
    const secondaryColor = Color(0xFF4DD0E1);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      
      // خطوط مخصصة للعربية في الثيم الداكن
      textTheme: GoogleFonts.cairoTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: Color(0xFFE0E0E0),
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: Color(0xFFBDBDBD),
        ),
      ),
      
      // إعدادات الكروت في الثيم الداكن
      cardTheme: const CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Color(0xFF2D2D2D),
      ),
      
      // شريط التطبيق في الثيم الداكن
      appBarTheme: const AppBarTheme(
        elevation: 2,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // الخلفية
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }
}
