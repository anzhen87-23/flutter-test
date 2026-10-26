# 应用配置完成总结

## ✅ 已完成的配置

### 1. 应用包名：`com.an.zhen`

**Android**
- 文件: `android/app/build.gradle.kts`
- 已更新:
  - `namespace = "com.an.zhen"`
  - `applicationId = "com.an.zhen"`

**iOS**
- 文件: `ios/Runner.xcodeproj/project.pbxproj`
- 已更新: `PRODUCT_BUNDLE_IDENTIFIER = com.an.zhen`

⚠️ **重要**: 包名已设定，发布后无法更改！

---

### 2. 应用图标配置

**配置文件**: `pubspec.yaml`
- ✅ 已添加 `flutter_launcher_icons` 依赖
- ✅ 已配置图标生成规则

**待完成**:
- ⏳ 准备 1024x1024 PNG 图标图片
- ⏳ 放置到 `assets/icon/app_icon.png`
- ⏳ 运行 `dart run flutter_launcher_icons` 生成图标

详细说明: 查看 `assets/icon/README.md`

---

### 3. API 环境配置

**配置文件**: `lib/config/env_config.dart`

**支持的环境**:
- `AppEnvironment.development` - 开发环境
- `AppEnvironment.production` - 生产环境

**使用方法**:
```dart
import 'package:personal_notes/config/env_config.dart';

// 在 main.dart 中设置环境
EnvConfig.setEnvironment(AppEnvironment.production);

// 获取 API 地址
String apiUrl = EnvConfig.apiBaseUrl;

// 其他配置
bool enableLog = EnvConfig.enableLogging;
int timeout = EnvConfig.requestTimeout;
```

**当前配置**:
- 开发环境: `http://localhost:8080/api`
- 生产环境: `https://api.yourdomain.com/api` ← **需要修改为实际地址**

---

## 📝 后续步骤

### 立即需要做的

1. **准备应用图标**
   ```bash
   # 将 1024x1024 的 PNG 图片放到
   assets/icon/app_icon.png
   
   # 生成图标
   flutter pub get
   dart run flutter_launcher_icons
   ```

2. **修改 API 地址**
   编辑 `lib/config/env_config.dart`，将生产环境地址改为实际 API 地址

3. **在 main.dart 中集成环境配置**
   ```dart
   import 'package:personal_notes/config/env_config.dart';
   
   void main() {
     // 根据构建类型设置环境
     EnvConfig.setEnvironment(
       kReleaseMode 
         ? AppEnvironment.production 
         : AppEnvironment.development
     );
     
     runApp(MyApp());
   }
   ```

### 验证配置

```bash
# 测试构建
./build_app.sh --android
./build_app.sh --ios-install
```

---

## 📂 新增/修改的文件

### 修改的文件
- `pubspec.yaml` - 添加图标生成配置
- `android/app/build.gradle.kts` - 更新包名
- `ios/Runner.xcodeproj/project.pbxproj` - 更新 Bundle ID

### 新增的文件
- `lib/config/env_config.dart` - API 环境配置
- `assets/icon/README.md` - 图标配置说明
- `build_app.sh` - 一键打包脚本（之前创建）

---

## 🔧 常用命令

```bash
# 生成应用图标
dart run flutter_launcher_icons

# 构建所有平台
./build_app.sh --all

# 仅构建 Android
./build_app.sh --android

# 构建并安装到 iPhone
./build_app.sh --ios-install

# 清理构建缓存
flutter clean
flutter pub get
```

---

## ⚠️ 注意事项

1. **包名不可更改**: `com.an.zhen` 已设定，发布后无法修改
2. **图标尺寸**: 必须是 1024x1024，不带圆角
3. **API 地址**: 记得修改生产环境的实际 API 地址
4. **版本管理**: 每次发布前更新 `pubspec.yaml` 中的 `version` 字段
5. **密钥库备份**: 备份 `~/upload-keystore.jks`，丢失后无法更新应用

---

## 📚 相关文档

- Android 打包: https://flutter.dev/docs/deployment/android
- iOS 打包: https://flutter.dev/docs/deployment/ios
- 应用图标: https://pub.dev/packages/flutter_launcher_icons
- 环境配置: 参考 `lib/config/env_config.dart`
