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
