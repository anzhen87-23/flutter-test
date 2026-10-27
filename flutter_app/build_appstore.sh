#!/bin/bash

# App Store 构建脚本
# 生成 IPA 用于上传到 App Store Connect

set -e

cd "$(dirname "$0")"

echo "=========================================="
echo "App Store 构建"
echo "=========================================="
echo ""

# 步骤 1: Flutter 构建 iOS Release
echo "📱 步骤 1: Flutter 构建 iOS Release..."
flutter build ios --release --no-codesign

if [ $? -ne 0 ]; then
    echo "❌ Flutter 构建失败"
    exit 1
fi

echo "✅ Flutter 构建完成"
echo ""

# 步骤 2: Archive
echo "📦 步骤 2: 创建 Archive..."

ARCHIVE_PATH="build/ios/AnZhenNotes.xcarchive"

xcodebuild archive \
    -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=N9Q5AGD8FW \
    PRODUCT_BUNDLE_IDENTIFIER=com.an.zhen \
    | grep -E "(BUILD|error:|warning:|Archive)" | tail -20

if [ $? -ne 0 ]; then
    echo "❌ Archive 失败"
    exit 1
fi

echo "✅ Archive 完成: $ARCHIVE_PATH"
echo ""

# 步骤 3: 导出 IPA
echo "📤 步骤 3: 导出 IPA..."

mkdir -p dist

# 创建 ExportOptions.plist
cat > /tmp/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>N9Q5AGD8FW</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

IPA_PATH="dist/AnZhenNotes.ipa"

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "dist" \
    -exportOptionsPlist /tmp/ExportOptions.plist \
    | grep -E "(export|error|warning)" | tail -10

if [ $? -ne 0 ]; then
    echo "❌ 导出 IPA 失败"
    exit 1
fi

# 检查 IPA 是否生成
if [ -f "$IPA_PATH" ]; then
    echo "✅ IPA 导出成功: $IPA_PATH"
    ls -lh "$IPA_PATH"
else
    # 可能在子目录中
    IPA_FILE=$(find dist -name "*.ipa" | head -1)
    if [ -n "$IPA_FILE" ]; then
        echo "✅ IPA 导出成功: $IPA_FILE"
        ls -lh "$IPA_FILE"
    else
        echo "️  未找到 IPA 文件"
        ls -la dist/
    fi
fi

echo ""
echo "=========================================="
echo "✅ App Store 构建完成！"
echo "=========================================="
echo ""
echo "📋 上传步骤："
echo "1. 打开 Transporter 应用 (App Store Connect)"
echo "2. 拖拽 IPA 文件到 Transporter"
echo "3. 等待上传完成"
echo "4. 在 App Store Connect 中提交审核"
echo ""
echo "或者使用命令行上传："
echo "xcrun altool --upload-app -f <IPA_PATH> -t ios -u <APPLE_ID> -p <APP_SPECIFIC_PASSWORD>"
echo ""
