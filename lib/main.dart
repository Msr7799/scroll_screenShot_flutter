// lib/main.dart
// نقطة البداية للتطبيق - تحتوي على إعدادات النافذة والتهيئة الأساسية

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/screens/home_screen.dart';
import 'services/screenshot_service.dart';

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
    size: Size(1000, 700),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Professional Screenshot Tool',
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScreenshotService()),
      ],
      child: MaterialApp(
        title: 'Professional Screenshot Tool',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.cairoTextTheme(),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}