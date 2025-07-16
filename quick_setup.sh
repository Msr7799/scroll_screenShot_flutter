#!/bin/bash

echo "🚀 إعداد سريع لتطبيق Screenshot Tool"
echo "========================================"

# التحقق من Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter غير مثبت. يرجى تثبيت Flutter أولاً."
    exit 1
fi

# التحقق من المتطلبات
echo "🔍 فحص المتطلبات..."

# فحص imagemagick
if command -v import &> /dev/null; then
    echo "✅ ImageMagick متوفر"
else
    echo "⚠️  ImageMagick غير مثبت"
    echo "   تثبيت: sudo apt install imagemagick"
fi

# فحص xdotool
if command -v xdotool &> /dev/null; then
    echo "✅ xdotool متوفر"
else
    echo "⚠️  xdotool غير مثبت"
    echo "   تثبيت: sudo apt install xdotool"
fi

# فحص X11
if [ -n "$DISPLAY" ]; then
    echo "✅ بيئة X11 متوفرة ($DISPLAY)"
else
    echo "❌ بيئة X11 غير متوفرة"
    echo "   تأكد من تشغيل واجهة رسومية"
fi

echo ""
echo "📦 تحديث التبعيات..."

# تنظيف وتحديث
flutter clean
flutter pub get

# إنشاء الأصول
echo "🎨 إنشاء الأصول..."
mkdir -p assets/icons

# إنشاء أيقونة بسيطة
cat > assets/icons/app-icon.svg << 'EOF'
<svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
  <rect width="128" height="128" rx="16" fill="#1976D2"/>
  <rect x="20" y="20" width="88" height="64" rx="8" fill="white" opacity="0.9"/>
  <rect x="24" y="24" width="80" height="56" rx="4" fill="#E3F2FD"/>
  <circle cx="32" cy="36" r="4" fill="#1976D2"/>
  <rect x="42" y="32" width="60" height="8" rx="4" fill="#BBDEFB"/>
  <rect x="24" y="48" width="80" height="2" fill="#90CAF9"/>
  <rect x="24" y="56" width="60" height="2" fill="#90CAF9"/>
  <rect x="24" y="64" width="40" height="2" fill="#90CAF9"/>
  <path d="M20 96 L40 84 L60 96 L80 84 L100 96 L108 92 L108 108 L20 108 Z" fill="white" opacity="0.8"/>
</svg>
EOF

echo "✅ تم إنشاء الأيقونة"

# إنشاء سكريبت تشغيل
cat > run.sh << 'EOF'
#!/bin/bash
echo "🚀 تشغيل Screenshot Tool..."

# التحقق من المتطلبات
if ! command -v import &> /dev/null; then
    echo "❌ يرجى تثبيت imagemagick: sudo apt install imagemagick"
    exit 1
fi

if ! command -v xdotool &> /dev/null; then
    echo "❌ يرجى تثبيت xdotool: sudo apt install xdotool"
    exit 1
fi

# تشغيل التطبيق
flutter run -d linux
EOF

chmod +x run.sh

echo ""
echo "🎉 تم الإعداد بنجاح!"
echo ""
echo "🏃 للتشغيل السريع:"
echo "   ./run.sh"
echo ""
echo "🔧 أو تشغيل يدوي:"
echo "   flutter run -d linux"
echo ""
echo "⚠️  ملاحظة مهمة:"
echo "   تأكد من تثبيت المتطلبات قبل التشغيل:"
echo "   sudo apt install imagemagick xdotool"