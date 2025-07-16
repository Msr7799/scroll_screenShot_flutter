// lib/ui/screens/home_screen.dart
// الشاشة الرئيسية - تحتوي على واجهة المستخدم الأساسية

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/screenshot_service.dart';
import '../../models/screenshot_config.dart';
import '../widgets/area_selector.dart';
import '../widgets/control_panel.dart';
import '../widgets/progress_indicator.dart';
import '../dialogs/settings_dialog.dart';
import 'preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ScreenshotConfig _config = ScreenshotConfig(
    x: 0,
    y: 0,
    width: 800,
    height: 600,
    outputPath: '/tmp/screenshots',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أداة السكرين شوت الاحترافية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
            tooltip: 'الإعدادات',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'المساعدة',
          ),
        ],
      ),
      body: Consumer<ScreenshotService>(
        builder: (context, service, child) {
          return Column(
            children: [
              // شريط التقدم
              if (service.isCapturing)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomProgressIndicator(
                    progress: service.progress,
                    status: service.status,
                  ),
                ),
              
              // المحتوى الرئيسي
              Expanded(
                child: Row(
                  children: [
                    // لوحة التحكم اليسرى
                    SizedBox(
                      width: 300,
                      child: ControlPanel(
                        config: _config,
                        onConfigChanged: (newConfig) {
                          setState(() {
                            _config = newConfig;
                          });
                        },
                        onStartCapture: () => _startCapture(service),
                        onStopCapture: () => service.stopCapture(),
                        onPauseCapture: () => service.pauseCapture(),
                        onResumeCapture: () => service.resumeCapture(),
                      ),
                    ),
                    
                    const VerticalDivider(),
                    
                    // منطقة اختيار المنطقة
                    Expanded(
                      child: AreaSelector(
                        config: _config,
                        onAreaSelected: (x, y, width, height) {
                          setState(() {
                            _config = _config.copyWith(
                              x: x,
                              y: y,
                              width: width,
                              height: height,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // شريط الحالة السفلي
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الحالة: ${service.status}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (service.capturedImages.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _showPreview(context, service),
                        icon: const Icon(Icons.visibility),
                        label: Text('معاينة (${service.capturedImages.length})'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// بدء عملية الالتقاط
  void _startCapture(ScreenshotService service) {
    service.startScrollingScreenshot(_config);
  }

  /// عرض نافذة الإعدادات
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        config: _config,
        onConfigChanged: (newConfig) {
          setState(() {
            _config = newConfig;
          });
        },
      ),
    );
  }

  /// عرض نافذة المساعدة
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة'),
        content: const SingleChildScrollView(
          child: Text(
            '''
طريقة الاستخدام:

1. حدد المنطقة المراد تصويرها من الشاشة
2. اضبط إعدادات السكرول والجودة
3. اضغط على "بدء الالتقاط" لبدء العملية
4. راقب التقدم ويمكنك الإيقاف المؤقت أو الإيقاف النهائي
5. بعد الانتهاء، يمكنك معاينة النتيجة وحفظها

المميزات:
- اكتشاف تلقائي لنهاية المحتوى
- تحكم كامل في الأبعاد
- جودة احترافية
- واجهة سهلة الاستخدام
            ''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// عرض شاشة المعاينة
  void _showPreview(BuildContext context, ScreenshotService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          capturedImages: service.capturedImages,
          onSave: () => service.savemergedImage(),
        ),
      ),
    );
  }
}