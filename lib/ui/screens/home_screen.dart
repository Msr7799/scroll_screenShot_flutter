// lib/ui/screens/home_screen.dart
// الشاشة الرئيسية الكاملة مع نظام التحديد الجديد

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  ScreenshotConfig _config = ScreenshotConfig(
    x: 0,
    y: 0,
    width: 800,
    height: 600,
    outputPath: '/tmp/screenshots',
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// تهيئة الرسوم المتحركة
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  /// تهيئة الخدمات
  void _initializeServices() {
    final screenshotService = Provider.of<ScreenshotService>(context, listen: false);
    screenshotService.initialize(_navigatorKey);
    _checkSystemRequirements();
  }

  /// التحقق من متطلبات النظام
  Future<void> _checkSystemRequirements() async {
    final screenshotService = Provider.of<ScreenshotService>(context, listen: false);
    final isSystemReady = await screenshotService.checkSystemRequirements();
    
    if (!isSystemReady && mounted) {
      _showSystemRequirementsDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: _buildAppBar(),
        body: Consumer<ScreenshotService>(
          builder: (context, service, child) {
            return Column(
              children: [
                // شريط التقدم والحالة
                if (service.isCapturing || service.isSelectingArea)
                  _buildStatusBar(service),
                
                // المحتوى الرئيسي
                Expanded(
                  child: service.isSelectingArea 
                      ? _buildSelectionMode()
                      : _buildNormalMode(service),
                ),
                
                // شريط الحالة السفلي
                _buildBottomStatusBar(service),
              ],
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: const Icon(Icons.screenshot_monitor, size: 28),
              );
            },
          ),
          const SizedBox(width: 12),
          const Text('أداة السكرين شوت الاحترافية'),
        ],
      ),
      elevation: 4,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        // زر تحديد المنطقة الرئيسي
        Consumer<ScreenshotService>(
          builder: (context, service, child) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: service.isCapturing 
                      ? [Colors.grey, Colors.grey.shade400]
                      : [Colors.green, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: service.isCapturing ? null : _startAreaSelection,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.crop_free, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'تحديد المنطقة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
      ],
    );
  }

  /// بناء شريط الحالة العلوي
  Widget _buildStatusBar(ScreenshotService service) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: service.isSelectingArea
              ? [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)]
              : [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          if (service.isCapturing)
            CustomProgressIndicator(
              progress: service.progress,
              status: service.status,
            ),
          
          if (service.isSelectingArea)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: const Icon(Icons.touch_app, color: Colors.orange),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'وضع تحديد المنطقة نشط',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'سيتم إخفاء النافذة وعرض الشاشة لتحديد المنطقة',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _cancelAreaSelection(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('إلغاء'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// بناء وضع التحديد
  Widget _buildSelectionMode() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.crop_free,
                      size: 64,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'تحديد المنطقة نشط',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'انتقل إلى الشاشة المطلوبة',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اسحب لتحديد المنطقة • Enter للتأكيد • Escape للإلغاء',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء الوضع العادي
  Widget _buildNormalMode(ScreenshotService service) {
    return Row(
      children: [
        // لوحة التحكم اليسرى
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
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
              onSelectArea: _startAreaSelection,
            ),
          ),
        ),
        
        // منطقة العرض الرئيسية
        Expanded(
          child: _buildMainArea(service),
        ),
      ],
    );
  }

  /// بناء المنطقة الرئيسية
  Widget _buildMainArea(ScreenshotService service) {
    if (service.capturedImages.isNotEmpty) {
      return _buildCaptureResults(service);
    } else {
      return _buildAreaSelector();
    }
  }

  /// بناء محدد المنطقة
  Widget _buildAreaSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  /// بناء نتائج الالتقاط
  Widget _buildCaptureResults(ScreenshotService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        child: Column(
          children: [
            // عنوان النتائج
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم التقاط ${service.capturedImages.length} صورة',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'المنطقة: ${_config.width} × ${_config.height} بكسل',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildResultActions(service),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // معاينة النتائج
            Expanded(
              child: _buildImageGrid(service),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء أزرار النتائج
  Widget _buildResultActions(ScreenshotService service) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.visibility,
          label: 'معاينة',
          color: Colors.blue,
          onPressed: () => _showPreview(context, service),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.save,
          label: 'حفظ',
          color: Colors.green,
          onPressed: () => _saveImages(service),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.clear,
          label: 'مسح',
          color: Colors.red,
          onPressed: () => service.clearCapture(),
        ),
      ],
    );
  }

  /// بناء زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء شبكة الصور
  Widget _buildImageGrid(ScreenshotService service) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: service.capturedImages.length,
        itemBuilder: (context, index) {
          final image = service.capturedImages[index];
          return Card(
            elevation: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    image.imageData,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// بناء شريط الحالة السفلي
  Widget _buildBottomStatusBar(ScreenshotService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // معلومات الحالة
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(service.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الحالة: ${service.status}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // معلومات إضافية
          if (service.capturedImages.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${service.capturedImages.length} صورة',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // زر المعاينة السريعة
          if (service.capturedImages.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _showPreview(context, service),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('معاينة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  /// بناء زر العمل العائم
  Widget? _buildFloatingActionButton() {
    return Consumer<ScreenshotService>(
      builder: (context, service, child) {
        if (service.isCapturing || service.isSelectingArea) {
          return const SizedBox.shrink();
        }
        
        return FloatingActionButton.extended(
          onPressed: _startAreaSelection,
          icon: const Icon(Icons.crop_free),
          label: const Text('تحديد منطقة'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        );
      },
    );
  }

  /// الحصول على لون الحالة
  Color _getStatusColor(String status) {
    if (status.contains('خطأ')) return Colors.red;
    if (status.contains('جاري')) return Colors.blue;
    if (status.contains('تم')) return Colors.green;
    if (status.contains('متوقف')) return Colors.orange;
    return Colors.grey;
  }

  /// بدء تحديد المنطقة
  Future<void> _startAreaSelection() async {
    final screenshotService = Provider.of<ScreenshotService>(context, listen: false);
    
    try {
      final selectedConfig = await screenshotService.startAreaSelection();
      
      if (selectedConfig != null && mounted) {
        setState(() {
          _config = selectedConfig;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديد المنطقة: ${selectedConfig.width} × ${selectedConfig.height}',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'بدء الالتقاط',
              onPressed: () => _startCapture(screenshotService),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديد المنطقة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// إلغاء تحديد المنطقة
  void _cancelAreaSelection() {
    // سيتم إلغاء العملية من خلال الخدمة
  }

  /// بدء عملية الالتقاط
  void _startCapture(ScreenshotService service) {
    HapticFeedback.mediumImpact();
    service.startScrollingScreenshot(_config);
  }

  /// حفظ الصور
  Future<void> _saveImages(ScreenshotService service) async {
    try {
      final savedPath = await service.saveMergedImage();
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الصورة في: ${savedPath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'فتح المجلد',
              onPressed: () => _openFileLocation(savedPath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// فتح موقع الملف
  void _openFileLocation(String filePath) {
    // يمكن تنفيذ فتح مدير الملفات هنا
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
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('المساعدة'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                'الميزة الجديدة: تحديد المنطقة من الشاشة',
                [
                  'اضغط على "تحديد المنطقة" في الشريط العلوي',
                  'سيتم إخفاء النافذة وتجميد الشاشة',
                  'اسحب لتحديد المنطقة المطلوبة',
                  'اضغط Enter للتأكيد أو Escape للإلغاء',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'طريقة الاستخدام العادية',
                [
                  'حدد المنطقة يدوياً أو استخدم القوالب',
                  'اضبط إعدادات السكرول والجودة',
                  'اضغط على "بدء الالتقاط"',
                  'راقب التقدم ويمكنك التحكم في العملية',
                  'بعد الانتهاء، معاينة وحفظ النتيجة',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'المتطلبات',
                [
                  'نظام Linux مع بيئة X11',
                  'imagemagick (أداة import)',
                  'xdotool (للسكرول التلقائي)',
                ],
              ),
            ],
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

  /// بناء قسم في المساعدة
  Widget _buildHelpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Colors.blue)),
              Expanded(child: Text(item)),
            ],
          ),
        )),
      ],
    );
  }

  /// عرض نافذة متطلبات النظام
  void _showSystemRequirementsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('متطلبات النظام'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يتطلب التطبيق الأدوات التالية للعمل بشكل صحيح:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRequirementItem(
              'ImageMagick',
              'sudo apt install imagemagick',
              Icons.image,
            ),
            const SizedBox(height: 8),
            _buildRequirementItem(
              'xdotool',
              'sudo apt install xdotool',
              Icons.mouse,
            ),
            const SizedBox(height: 8),
            _buildRequirementItem(
              'X11 Display Server',
              'تأكد من تشغيل بيئة X11',
              Icons.desktop_windows,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'بعض الميزات قد لا تعمل بدون هذه الأدوات. '
                    'يمكنك المتابعة لكن الوظائف ستكون محدودة.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تجاهل'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkSystemRequirements();
            },
            child: const Text('إعادة فحص'),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر متطلب
  Widget _buildRequirementItem(String name, String command, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  command,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ الأمر للحافظة'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'نسخ الأمر',
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
          onSave: () => service.saveMergedImage(),
        ),
      ),
    );
  }
}