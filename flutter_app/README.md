# Personal Notes Flutter App

个人笔记应用 Flutter 移动端。

## 技术栈

- **Flutter 3.0+** (Dart)
- **Material Design 3**
- **http** (HTTP 请求)
- **shared_preferences** (本地存储)

## 项目结构

```
flutter_app/
├── pubspec.yaml              # 依赖配置
├── lib/
│   ├── main.dart             # 应用入口
│   ├── models/               # 数据模型
│   │   ├── user.dart         # 用户模型
│   │   ├── note.dart         # 笔记模型
│   │   └── folder.dart       # 文件夹模型
│   ├── services/             # 服务层
│   │   └── api_service.dart  # API 客户端
│   ├── utils/                # 工具类
│   │   └── validators.dart   # 验证工具
│   └── pages/                # 页面
│       ├── login_page.dart       # 登录页
│       ├── register_page.dart    # 注册页
│       ├── reset_password_page.dart # 重置密码
│       ├── home_page.dart        # 主页（底部导航）
│       ├── notes_list_page.dart  # 笔记列表
│       ├── note_editor_page.dart # 笔记编辑
│       ├── folders_page.dart     # 文件夹管理
│       └── profile_page.dart     # 个人中心
└── test/
    ├── unit/                 # 单元测试
    │   └── validators_test.dart
    ├── widget/               # Widget 测试
    │   └── app_test.dart
    └── integration/          # 集成测试
        └── app_test.dart
```

## 快速启动

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run

# 构建 APK
flutter build apk

# 构建 iOS
flutter build ios
```

## 功能页面

| 页面 | 说明 |
|------|------|
| 登录 | 手机号/邮箱/用户名登录 |
| 注册 | 手机号/邮箱注册，验证码 |
| 重置密码 | 验证码重置密码 |
| 笔记列表 | 分页、文件夹筛选 |
| 笔记编辑 | 新建/编辑笔记 |
| 文件夹 | 创建/重命名/删除 |
| 个人中心 | 昵称/生日/手机/邮箱/密码管理 |

## 验证规则（与后端/Web统一）

- ✅ 密码: 6位纯数字 (`^\d{6}$`)
- ✅ 手机号: 中国大陆11位 (`^1[3-9]\d{9}$`)
- ✅ 邮箱: 标准格式
- ✅ 验证码: 6位数字
- ✅ 笔记标题: ≤200字符

## 运行测试

```bash
# 单元测试
flutter test test/unit/

# Widget 测试
flutter test test/widget/

# 集成测试（需要设备）
flutter test integration_test/app_test.dart

# 所有测试
flutter test
```

## 测试统计

- **单元测试**: 21 个 (验证工具)
- **Widget 测试**: 4 个 (应用启动/表单验证/页面导航)
- **集成测试**: 4 个 (完整流程)
- **总计**: 29 个测试

## 特性

- ✅ Material Design 3 风格
- ✅ 响应式布局
- ✅ 表单验证
- ✅ 下拉刷新
- ✅ 加载状态
- ✅ 错误处理
- ✅ Token 持久化
- ✅ 统一验证规则
