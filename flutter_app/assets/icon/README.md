# 应用图标配置说明

## 需要准备的文件

在 `assets/icon/` 目录下放置以下图片：

### 1. app_icon.png（必需）
- **尺寸**: 1024x1024 像素
- **格式**: PNG（透明背景）
- **要求**: 不带圆角（系统自动处理）
- **用途**: 自动生成各平台所需的所有尺寸

## 生成图标

准备好图片后，运行以下命令：

```bash
# 获取依赖
flutter pub get

# 生成图标
dart run flutter_launcher_icons
```

这会自动：
- 为 Android 生成各种尺寸的图标（mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi）
- 为 iOS 生成 AppIcon.appiconset
- 自动更新配置文件

## 验证

构建应用查看效果：
```bash
./build_app.sh --android
./build_app.sh --ios-install
```

## 设计建议

1. **简洁明了**: 避免过多细节，小尺寸下也要清晰可辨
2. **对比度高**: 确保在浅色/深色背景下都可见
3. **避免文字**: 不同语言下文字可能显示不全
4. **独特性**: 与应用商店其他应用区分开
5. **品牌一致性**: 与你的品牌/网站风格保持一致

## 在线工具

如果需要设计或调整图标：
- Figma: https://www.figma.com
- Canva: https://www.canva.com
- Icon Kitchen: https://icon.kitchen

## 当前状态

- ✅ 配置文件已就绪 (`pubspec.yaml`)
- ⏳ 等待提供图标图片 (`assets/icon/app_icon.png`)
