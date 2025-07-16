#!/bin/bash

# سكريبت إنشاء أيقونة التطبيق والأصول

echo "🎨 إنشاء أيقونة التطبيق والأصول..."

# إنشاء مجلد الأصول
mkdir -p assets/icons

# إنشاء أيقونة بسيطة باستخدام ImageMagick
if command -v convert &> /dev/null; then
    echo "📷 إنشاء أيقونة التطبيق..."
    
    # إنشاء أيقونة 512x512 بسيطة
    convert -size 512x512 xc:white \
        -fill "#1976D2" \
        -draw "roundrectangle 50,50 462,462 50,50" \
        -fill white \
        -pointsize 120 \
        -gravity center \
        -draw "text 0,-20 '📱'" \
        -pointsize 60 \
        -draw "text 0,60 'Screenshot'" \
        assets/icons/app-icon.png
    
    # إنشاء أيقونة SVG بسيطة
    cat > assets/icons/app-icon.svg << 'EOF'
<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
  <rect width="512" height="512" rx="50" fill="#1976D2"/>
  <text x="256" y="200" font-family="Arial" font-size="120" fill="white" text-anchor="middle">📱</text>
  <text x="256" y="320" font-family="Arial" font-size="48" fill="white" text-anchor="middle">Screenshot</text>
  <text x="256" y="380" font-family="Arial" font-size="32" fill="white" text-anchor="middle">Tool</text>
</svg>
EOF

    echo "✅ تم إنشاء الأيقونات بنجاح"
else
    echo "⚠️  ImageMagick غير مثبت. إنشاء أيقونة بسيطة..."
    
    # إنشاء أيقونة SVG فقط
    cat > assets/icons/app-icon.svg << 'EOF'
<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
  <rect width="512" height="512" rx="50" fill="#1976D2"/>
  <circle cx="256" cy="180" r="80" fill="white"/>
  <rect x="200" y="280" width="112" height="80" rx="10" fill="white"/>
  <text x="256" y="400" font-family="Arial" font-size="36" fill="white" text-anchor="middle">Screenshot</text>
</svg>
EOF

    echo "✅ تم إنشاء أيقونة SVG"
fi

# إنشاء ملف معلومات التطبيق للينكس
mkdir -p linux
cat > linux/my_application.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Screenshot Tool
Comment=Professional scrolling screenshot app
Icon=screenshot-tool
Exec=scroll_screenshot_app
Categories=Graphics;Photography;
EOF

echo "📁 تم إنشاء ملفات التطبيق للينكس"

# إنشاء سكريبت بناء بسيط
cat > build.sh << 'EOF'
#!/bin/bash

echo "🔨 بناء تطبيق Screenshot Tool..."

# تنظيف المشروع
flutter clean

# تحديث التبعيات
flutter pub get

# بناء للينكس
flutter build linux --release

echo "✅ تم البناء بنجاح!"
echo "📁 يمكنك العثور على التطبيق في: build/linux/x64/release/bundle/"

# نسخ التطبيق لمجلد محلي (اختياري)
if [ -d "build/linux/x64/release/bundle" ]; then
    echo "📦 نسخ التطبيق للمجلد المحلي..."
    cp -r build/linux/x64/release/bundle ./screenshot_tool_release
    echo "✅ تم النسخ إلى: ./screenshot_tool_release"
fi
EOF

chmod +x build.sh

echo ""
echo "🎉 تم إعداد كل شيء بنجاح!"
echo ""
echo "📋 الخطوات التالية:"
echo "1. تشغيل: flutter pub get"
echo "2. تشغيل: flutter run -d linux"
echo "3. أو بناء التطبيق: ./build.sh"
echo ""
echo "📁 الملفات المُنشأة:"
echo "   ├── assets/icons/app-icon.svg"
echo "   ├── assets/icons/app-icon.png (إذا كان ImageMagick متوفر)"
echo "   ├── linux/my_application.desktop"
echo "   └── build.sh"