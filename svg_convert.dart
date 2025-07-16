import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  const svgPath = 'assets/icons/app-icon.svg';
  final dirName = p.dirname(svgPath);
  final baseName = p.basenameWithoutExtension(svgPath);
  final pngPath = p.join(dirName, '$baseName.png');

  // التأكد من وجود مجلد الأيقونات
  if (!Directory(dirName).existsSync()) {
    Directory(dirName).createSync(recursive: true);
  }

  // التأكد من وجود ملف SVG
  if (!File(svgPath).existsSync()) {
    print('ملف SVG غير موجود: $svgPath');
    return;
  }

  // التأكد من وجود برنامج cairosvg في النظام
  final cairosvgExists = await Process.run('which', ['cairosvg']);
  if (cairosvgExists.exitCode != 0) {
    print('برنامج cairosvg غير موجود في النظام');
    return;
  }

  // تحويل SVG إلى PNG باستخدام cairosvg
  final pngResult = await Process.run(
    'cairosvg',
    [svgPath, '-o', pngPath, '-W', '512', '-H', '512'],
  );

  if (pngResult.exitCode == 0 && File(pngPath).existsSync()) {
    print('تم تحويل SVG إلى PNG بنجاح: $pngPath');
  } else {
    print('فشل تحويل SVG إلى PNG: ${pngResult.stderr}');
  }
}