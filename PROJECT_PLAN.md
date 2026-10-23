# 个人笔记应用开发计划

## 项目概述

一个支持多端的个人笔记管理应用，包含用户认证、笔记管理和目录管理功能。

**技术栈：**
- 后端：Golang (Gin框架 + SQLite)
- Web端：原生 JavaScript (HTML + CSS + JS)
- 移动端：Flutter (Dart)

---

## 功能模块

### 1. 用户认证模块
- 用户注册（支持手机号或邮箱注册）
- 用户登录（手机号/邮箱 + 6位数字密码）
- JWT Token 认证
- 自动登录
- 修改密码（需验证旧密码）
- 忘记密码（通过手机号/邮箱验证码重置）

### 2. 笔记管理模块
- 新建笔记
- 查看笔记列表
- 查看笔记详情
- 编辑笔记
- 删除笔记
- 笔记搜索（可选，后续扩展）

### 3. 目录管理模块
- 新建目录
- 查看目录列表
- 删除目录
- 目录下的笔记管理

### 4. 个人信息模块
- 查看个人信息（昵称、头像、生日、手机号、邮箱）
- 修改昵称
- 修改头像（支持上传图片）
- 修改生日（日期选择器）
- 修改手机号（需短信验证）
- 修改邮箱（需邮箱验证）
- 修改密码（需验证旧密码 + 新密码6位数字）

---

## 技术架构设计

### 后端架构 (Golang)

**技术选型：**
- Web框架：Gin
- 数据库：SQLite (轻量级，适合个人应用)
- 认证：JWT
- ORM：GORM

**项目结构：**
```
backend/
├── main.go              # 入口文件
├── config/
│   └── config.go        # 配置管理
├── models/
│   ├── user.go          # 用户模型
│   ├── note.go          # 笔记模型
│   ├── folder.go        # 目录模型
│   └── avatar.go        # 头像与验证码模型
├── handlers/
│   ├── auth.go          # 认证处理器（登录/注册/验证码/重置密码）
│   ├── auth_test.go     # 认证处理器单元测试
│   ├── note.go          # 笔记处理器
│   ├── note_test.go     # 笔记处理器单元测试
│   ├── folder.go        # 目录处理器
│   ├── folder_test.go   # 目录处理器单元测试
│   ├── profile.go       # 个人信息处理器
│   ├── profile_test.go  # 个人信息处理器单元测试
│   └── upload.go        # 文件上传处理器
├── services/
│   ├── sms.go           # 短信服务（验证码）
│   └── email.go         # 邮件服务（验证码）
├── utils/
│   ├── password.go      # 密码工具（6位数字验证）
│   ├── password_test.go # 密码工具单元测试
│   ├── phone.go         # 手机号工具（格式验证、脱敏）
│   ├── phone_test.go    # 手机号工具单元测试
│   ├── verification.go  # 验证码工具
│   ├── email.go         # 邮件发送
│   └── sms.go           # 短信发送
├── middleware/
│   └── auth.go          # JWT中间件
├── database/
│   └── database.go      # 数据库初始化
├── routes/
│   └── routes.go        # 路由定义
├── uploads/             # 上传文件存储目录
│   └── avatars/
├── tests/
│   ├── setup.go         # 测试公共配置
│   ├── auth_test.go     # 认证集成测试
│   ├── note_test.go     # 笔记集成测试
│   ├── folder_test.go   # 目录集成测试
│   ├── profile_test.go  # 个人信息集成测试
│   └── benchmark_test.go # 性能压测
└── go.mod
```

**数据库设计：**

```sql
-- 用户表
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,           -- 用户名（登录账号）
    phone VARCHAR(20) UNIQUE,                        -- 手机号（可选，用于登录）
    email VARCHAR(100) UNIQUE,                       -- 邮箱（可选，用于登录）
    password VARCHAR(255) NOT NULL,                  -- 6位数字密码（bcrypt加密）
    nickname VARCHAR(50),                            -- 昵称
    avatar_url VARCHAR(500),                         -- 头像URL
    birthday DATE,                                   -- 生日
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- 必须通过手机号或邮箱之一注册
    CHECK (phone IS NOT NULL OR email IS NOT NULL)
);

-- 头像表（可选，支持头像版本管理）
CREATE TABLE avatars (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 验证码表（用于手机号/邮箱验证）
CREATE TABLE verification_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    target VARCHAR(100) NOT NULL,                    -- 手机号或邮箱
    code VARCHAR(6) NOT NULL,                        -- 6位验证码
    type VARCHAR(20) NOT NULL,                       -- register/reset/verify
    expires_at DATETIME NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 目录表
CREATE TABLE folders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 笔记表
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    folder_id INTEGER,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (folder_id) REFERENCES folders(id)
);
```

### Web端架构 (JavaScript)

**技术选型：**
- 原生 JavaScript (ES6+)
- Fetch API (HTTP请求)
- LocalStorage (本地存储)

**项目结构：**
```
web/
├── index.html              # 主页（笔记和目录管理）
├── login.html              # 登录页（手机号/邮箱/用户名登录）
├── register.html           # 注册页（手机号/邮箱切换 + 验证码 + 6位密码）
├── profile.html            # 个人信息主页
├── change-password.html    # 修改密码页
├── css/
│   └── style.css           # 样式文件
├── js/
│   ├── app.js              # 主应用逻辑
│   ├── auth.js             # 认证相关
│   ├── api.js              # API调用封装
│   ├── notes.js            # 笔记管理
│   ├── folders.js          # 目录管理
│   └── profile.js          # 个人信息管理
├── __tests__/              # Jest 单元测试目录
│   ├── auth.test.js        # 认证功能测试
│   ├── notes.test.js       # 笔记功能测试
│   ├── folders.test.js     # 目录功能测试
│   ├── profile.test.js     # 个人信息测试
│   ├── components.test.js  # UI组件测试
│   └── api.test.js         # API调用测试
├── e2e/                    # Playwright E2E 测试目录
│   ├── auth.spec.js        # 认证流程E2E测试
│   ├── notes.spec.js       # 笔记流程E2E测试
│   ├── folders.spec.js     # 目录流程E2E测试
│   ├── profile.spec.js     # 个人信息流程E2E测试
│   └── full-flow.spec.js   # 完整用户流程
├── perf/                   # 性能测试目录
│   ├── lighthouse.config.js
│   ├── lighthouse-ci.config.js
│   ├── performance.test.js
│   ├── bundle-analysis.js
│   ├── metrics/
│   │   └── web-vitals.js
│   └── load/
│       ├── auth-load.js
│       └── full-load.js
└── assets/
    ├── images/             # 静态资源
    └── default-avatar.png  # 默认头像
```

**页面交互说明：**
- `profile.html` 为个人信息主页，展示所有个人信息
- 修改昵称/生日：在 `profile.html` 中通过**模态框**实现
- 修改头像/手机号/邮箱：在 `profile.html` 中通过**模态框**实现（含验证码流程）
- 修改密码：跳转到独立的 `change-password.html` 页面（涉及敏感操作）

### 移动端架构 (Flutter)

**技术选型：**
- Flutter 3.x
- Dart
- HTTP package
- Shared Preferences (本地存储)

**项目结构：**
```
mobile/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── note.dart
│   │   └── folder.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   └── profile_service.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart      # 支持手机号/邮箱注册
│   │   ├── home_screen.dart
│   │   ├── note_list_screen.dart
│   │   ├── note_edit_screen.dart
│   │   ├── profile_screen.dart       # 个人信息页
│   │   ├── change_password_screen.dart # 修改密码页
│   │   ├── change_avatar_screen.dart  # 修改头像页
│   │   ├── change_birthday_screen.dart # 修改生日页（日期选择器）
│   │   ├── verify_phone_screen.dart   # 手机号验证页
│   │   └── verify_email_screen.dart   # 邮箱验证页
│   └── widgets/
│       ├── note_card.dart
│       ├── folder_list_item.dart
│       ├── avatar_widget.dart         # 头像组件
│       └── code_input_widget.dart     # 验证码输入组件
├── pubspec.yaml
└── test/
```

---

## API设计

### 认证接口

```
# 发送验证码（注册/重置密码/修改手机号/修改邮箱）
POST /api/auth/send-code
Request: { "target": "13800138000", "type": "register" }
        // type: register | reset_password | verify_phone | verify_email
Response: { "code": 200, "message": "验证码已发送", "data": { "expires_in": 300 } }

# 手机号注册（6位数字密码）
POST /api/auth/register/phone
Request: {
    "phone": "13800138000",
    "code": "123456",           // 短信验证码
    "password": "123456",       // 6位数字密码
    "nickname": "小明"          // 可选
}
Response: { "code": 200, "data": { "user_id": 1, "token": "jwt_token" } }

# 邮箱注册（6位数字密码）
POST /api/auth/register/email
Request: {
    "email": "user@example.com",
    "code": "654321",           // 邮箱验证码
    "password": "123456",       // 6位数字密码
    "nickname": "小明"          // 可选
}
Response: { "code": 200, "data": { "user_id": 1, "token": "jwt_token" } }

# 登录（支持手机号/邮箱/用户名）
POST /api/auth/login
Request: {
    "account": "13800138000",   // 手机号/邮箱/用户名
    "password": "123456"        // 6位数字密码
}
Response: {
    "code": 200,
    "data": {
        "token": "jwt_token",
        "user": {
            "id": 1,
            "username": "xiaoming",
            "phone": "13800138000",
            "email": "user@example.com",
            "nickname": "小明",
            "avatar_url": "https://...",
            "birthday": "1990-01-01"
        }
    }
}

# 忘记密码（重置密码）
POST /api/auth/reset-password
Request: {
    "account": "13800138000",   // 手机号或邮箱
    "code": "123456",           // 验证码
    "new_password": "654321"    // 新的6位数字密码
}
Response: { "code": 200, "message": "密码重置成功" }
```

### 个人信息接口

```
# 获取个人信息
GET /api/profile
Headers: Authorization: Bearer <token>
Response: {
    "code": 200,
    "data": {
        "id": 1,
        "username": "xiaoming",
        "phone": "13800138000",
        "email": "user@example.com",
        "nickname": "小明",
        "avatar_url": "https://example.com/avatars/1.jpg",
        "birthday": "1990-01-01"
    }
}

# 修改昵称
PUT /api/profile/nickname
Headers: Authorization: Bearer <token>
Request: { "nickname": "新昵称" }
Response: { "code": 200, "message": "修改成功", "data": { "nickname": "新昵称" } }

# 修改头像（上传头像图片）
POST /api/profile/avatar
Headers:
    Authorization: Bearer <token>
    Content-Type: multipart/form-data
Request: { "avatar": <file> }
Response: {
    "code": 200,
    "message": "头像上传成功",
    "data": { "avatar_url": "https://example.com/avatars/new_avatar.jpg" }
}

# 修改生日
PUT /api/profile/birthday
Headers: Authorization: Bearer <token>
Request: { "birthday": "1995-06-15" }
Response: { "code": 200, "message": "修改成功", "data": { "birthday": "1995-06-15" } }

# 修改手机号（需验证码验证）
PUT /api/profile/phone
Headers: Authorization: Bearer <token>
Request: {
    "phone": "13900139000",
    "code": "123456"   // 发送到新手机号的验证码
}
Response: { "code": 200, "message": "手机号修改成功" }

# 修改邮箱（需验证码验证）
PUT /api/profile/email
Headers: Authorization: Bearer <token>
Request: {
    "email": "new@example.com",
    "code": "654321"   // 发送到新邮箱的验证码
}
Response: { "code": 200, "message": "邮箱修改成功" }

# 修改密码（需验证旧密码）
PUT /api/profile/password
Headers: Authorization: Bearer <token>
Request: {
    "old_password": "123456",   // 旧6位数字密码
    "new_password": "654321"    // 新6位数字密码
}
Response: { "code": 200, "message": "密码修改成功" }
```

### 笔记接口

```
GET    /api/notes          # 获取笔记列表
Response: { "code": 200, "data": [{ "id": 1, "title": "...", "content": "...", "folder_id": 1 }] }

GET    /api/notes/:id      # 获取单个笔记
Response: { "code": 200, "data": { "id": 1, "title": "...", "content": "...", "folder_id": 1 } }

POST   /api/notes          # 创建笔记
Request: { "title": "string", "content": "string", "folder_id": 1 }
Response: { "code": 200, "message": "success", "data": { "note_id": 1 } }

PUT    /api/notes/:id      # 更新笔记
Request: { "title": "string", "content": "string", "folder_id": 1 }
Response: { "code": 200, "message": "success" }

DELETE /api/notes/:id      # 删除笔记
Response: { "code": 200, "message": "success" }
```

### 目录接口

```
GET    /api/folders        # 获取目录列表
Response: { "code": 200, "data": [{ "id": 1, "name": "...", "note_count": 5 }] }

POST   /api/folders        # 创建目录
Request: { "name": "string" }
Response: { "code": 200, "message": "success", "data": { "folder_id": 1 } }

DELETE /api/folders/:id    # 删除目录
Response: { "code": 200, "message": "success" }
```

---

## 开发步骤

### 第一阶段：后端开发 (预计3天)

**Day 1:**
1. 初始化Go项目，安装依赖（Gin、GORM、JWT、bcrypt）
2. 创建数据库模型和初始化数据库
3. 实现用户模型（包含新增字段：phone、nickname、avatar_url、birthday）
4. 实现密码工具类（6位数字密码验证 + bcrypt加密）

**Day 2:**
1. 实现验证码服务（短信/邮件发送）
2. 实现验证码接口（发送验证码）
3. 实现手机号注册接口
4. 实现邮箱注册接口
5. 实现登录接口（支持手机号/邮箱/用户名）
6. 实现JWT认证中间件

**Day 3:**
1. 实现目录CRUD接口
2. 实现笔记CRUD接口
3. 实现个人信息接口（查看、修改昵称、生日、头像、手机、邮箱、密码）
4. 实现文件上传接口（头像上传）
5. 添加错误处理和日志记录
6. 测试所有API接口

### 第二阶段：Web端开发 (预计3天)

**Day 4:**
1. 创建HTML页面结构（login、register、index、profile、change-password）
2. 实现CSS样式设计
3. 实现登录页面（支持手机号/邮箱/用户名登录）
4. 实现注册页面（手机号/邮箱注册 + 验证码输入 + 6位数字密码）
5. 实现JWT Token存储和管理

**Day 5:**
1. 实现主页布局和导航
2. 实现目录列表和管理功能
3. 实现笔记列表和编辑功能
4. 实现个人信息页面（查看和编辑所有个人信息）

**Day 6:**
1. 实现头像上传功能
2. 实现生日日期选择器
3. 实现修改密码页面（验证旧密码 + 新密码）
4. 实现手机号/邮箱修改页面（验证码输入）
5. 优化用户体验和界面

### 第三阶段：移动端开发 (预计4天)

**Day 7:**
1. 初始化Flutter项目
2. 配置网络请求服务
3. 实现登录页面（支持手机号/邮箱/用户名登录）
4. 实现注册页面（手机号/邮箱切换、验证码、6位数字密码）
5. 实现Token管理

**Day 8:**
1. 实现主页和目录列表
2. 实现笔记列表页面
3. 实现笔记编辑页面
4. 实现数据模型和状态管理

**Day 9:**
1. 实现个人信息页面
2. 实现头像上传（使用 image_picker 包）
3. 实现生日选择器（使用 CupertinoDatePicker）
4. 实现修改密码页面
5. 实现手机号/邮箱验证码修改流程

**Day 10:**
1. 优化UI/UX
2. 添加加载状态和错误处理
3. 测试所有功能
4. 修复bug

### 第四阶段：测试和优化 (预计1天)

**Day 11:**
1. 端到端测试（包含新的个人信息流程）
2. 性能优化
3. 安全性检查（密码强度、验证码安全）
4. 文档编写

---

## 安全考虑

1. **密码安全：**
   - 使用bcrypt加密存储
   - 强制6位数字密码（简单密码，但符合个人应用需求）
   - 修改密码需验证旧密码
   - 密码不能与旧密码相同

2. **验证码安全：**
   - 验证码6位数字，5分钟过期
   - 验证码使用后立即失效
   - 限制发送频率（如：60秒内不能重发）
   - 每个手机号/邮箱每天最多发送10次
   - 验证码使用bcrypt加密存储

3. **认证安全：**
   - JWT token设置合理过期时间（如：7天）
   - 支持Token刷新机制
   - 登录失败次数限制（如：5次失败锁定30分钟）

4. **头像上传安全：**
   - 限制文件类型（只允许 jpg、jpeg、png、gif）
   - 限制文件大小（最大5MB）
   - 对上传文件进行病毒扫描
   - 使用唯一文件名防止覆盖
   - 上传目录禁止执行脚本

5. **数据安全：**
   - CORS：配置允许的源
   - 输入验证：所有用户输入进行验证和清理
   - SQL注入防护：使用ORM参数化查询
   - XSS防护：Web端对用户输入进行转义
   - 手机号/邮箱脱敏显示（如：138****8000）

6. **接口安全：**
   - 敏感操作（修改手机号、邮箱、密码）需要验证码
   - 验证码校验后才允许修改
   - 检查目标手机号/邮箱是否被其他用户占用
   - 所有敏感操作记录日志

---

## 统一验证规则规范（三端必须一致）

为确保三端行为一致，以下验证规则必须在**后端、Web端、Flutter端**统一实现：

### 密码
```
规则：必须为6位纯数字
正则：^\d{6}$
错误提示："密码必须为6位数字"
后端实现：utils/password.go - ValidatePassword()
Web实现：js/auth.js - validatePassword()
Flutter实现：utils/password_validator.dart
```

### 手机号
```
规则：中国大陆手机号，11位，以1[3-9]开头
正则：^1[3-9]\d{9}$
错误提示："手机号格式错误"
后端实现：utils/phone.go - ValidatePhone()
Web实现：js/auth.js - validatePhone()
Flutter实现：utils/phone_validator.dart
脱敏显示：138****8000
```

### 邮箱
```
规则：标准邮箱格式
正则：^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
错误提示："邮箱格式错误"
后端实现：Gin binding:"email"
Web实现：js/auth.js - validateEmail()
Flutter实现：utils/email_validator.dart
```

### 昵称
```
规则：1-50字符
错误提示："昵称长度应在1-50个字符之间"
后端实现：Gin binding:"required,min=1,max=50"
Web实现：js/profile.js
Flutter实现：screens/profile_screen.dart
```

### 头像
```
允许类型：jpg, jpeg, png, gif
最大大小：5MB
错误提示：
  - "只支持 jpg、jpeg、png、gif 格式的图片"
  - "头像大小不能超过5MB"
后端实现：handlers/upload.go
Web实现：js/profile.js
Flutter实现：screens/change_avatar_screen.dart
```

### 生日
```
格式：YYYY-MM-DD
限制：不能在未来
错误提示：
  - "日期格式错误，应为 YYYY-MM-DD"
  - "生日不能在未来"
后端实现：handlers/profile.go - UpdateBirthday()
Web实现：js/profile.js
Flutter实现：screens/change_birthday_screen.dart
```

### 验证码
```
长度：6位数字
有效期：5分钟
发送频率限制：60秒内不能重发
每日上限：10次/手机号/邮箱
错误提示："验证码错误或已过期"
后端实现：utils/verification.go - VerifyCode()
Web实现：js/auth.js - verifyCode()
Flutter实现：services/auth_service.dart
```

### 统一响应格式
```json
成功响应：
{
  "code": 200,
  "message": "success",
  "data": { ... }
}

错误响应：
{
  "code": 400 | 401 | 404 | 409 | 500,
  "message": "具体错误描述",
  "data": null
}
```

### 统一状态码
| 状态码 | 含义 | 三端处理 |
|--------|------|----------|
| 200 | 成功 | 正常处理 |
| 400 | 参数错误 | 显示message给用户 |
| 401 | 未授权 | 清除Token，跳转登录页 |
| 404 | 资源不存在 | 显示"不存在"提示 |
| 409 | 资源冲突 | 显示冲突原因（如已注册） |
| 500 | 服务器错误 | 显示"服务器错误，请稍后重试" |
| 网络错误 | 无法连接 | 显示"网络错误，请检查网络" |

---

## 扩展功能 (可选，后续实现)

1. 笔记标签功能
2. 笔记搜索功能
3. 笔记导出 (PDF, Markdown)
4. 图片上传和嵌入
5. 富文本编辑器
6. 笔记分享功能
7. 数据备份和恢复
8. 多设备同步

---

## 项目启动顺序

建议按以下顺序进行开发：

1. **先完成后端API** - 这是整个应用的核心
2. **再开发Web端** - 便于测试和调试
3. **最后开发移动端** - 基于稳定的后端API

---

## 开发环境要求

- Go 1.21+
- Node.js 16+ (用于Web端开发工具)
- Flutter 3.x
- Git

---

## 测试计划

### 一、后端测试 (Golang)

#### 1.1 单元测试

**测试框架：** `testing` (标准库) + `testify` (断言库)

**项目测试结构：**
```
backend/
├── handlers/
│   ├── auth.go
│   ├── auth_test.go          # 认证处理器单元测试
│   ├── note.go
│   ├── note_test.go          # 笔记处理器单元测试
│   ├── folder.go
│   └── folder_test.go        # 目录处理器单元测试
├── middleware/
│   ├── auth.go
│   └── auth_test.go          # JWT中间件单元测试
├── models/
│   ├── user.go
│   ├── user_test.go          # 用户模型单元测试
│   ├── note.go
│   ├── note_test.go          # 笔记模型单元测试
│   ├── folder.go
│   └── folder_test.go        # 目录模型单元测试
└── tests/
    ├── setup.go              # 测试公共配置
    ├── auth_test.go          # 认证集成测试
    ├── note_test.go          # 笔记集成测试
    ├── folder_test.go        # 目录集成测试
    └── benchmark_test.go     # 性能压测
```

**单元测试示例：**

**认证处理器测试 (`handlers/auth_test.go`)：**
```go
package handlers

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/gin-gonic/gin"
)

func TestRegisterByPhone(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)

    // 先创建一个验证码（模拟短信发送）
    createTestVerificationCode(db, "13800138000", "123456", "register")

    tests := []struct {
        name           string
        requestBody    map[string]string
        expectedStatus int
        expectedCode   int
    }{
        {
            name: "手机号注册成功",
            requestBody: map[string]string{
                "phone":    "13800138000",
                "code":     "123456",
                "password": "123456",
                "nickname": "测试用户",
            },
            expectedStatus: http.StatusOK,
            expectedCode:   200,
        },
        {
            name: "缺少手机号",
            requestBody: map[string]string{
                "code":     "123456",
                "password": "123456",
            },
            expectedStatus: http.StatusBadRequest,
            expectedCode:   400,
        },
        {
            name: "密码不是6位数字",
            requestBody: map[string]string{
                "phone":    "13800138001",
                "code":     "123456",
                "password": "12345",
            },
            expectedStatus: http.StatusBadRequest,
            expectedCode:   400,
        },
        {
            name: "验证码错误",
            requestBody: map[string]string{
                "phone":    "13800138002",
                "code":     "999999",
                "password": "123456",
            },
            expectedStatus: http.StatusBadRequest,
            expectedCode:   400,
        },
        {
            name: "手机号格式错误",
            requestBody: map[string]string{
                "phone":    "12345678901",
                "code":     "123456",
                "password": "123456",
            },
            expectedStatus: http.StatusBadRequest,
            expectedCode:   400,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(tt.requestBody)
            req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)

            var response map[string]interface{}
            json.Unmarshal(w.Body.Bytes(), &response)
            assert.Equal(t, float64(tt.expectedCode), response["code"])
        })
    }
}

func TestRegisterByEmail(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)

    // 创建验证码
    createTestVerificationCode(db, "test@example.com", "654321", "register")

    tests := []struct {
        name           string
        requestBody    map[string]string
        expectedStatus int
        expectedCode   int
    }{
        {
            name: "邮箱注册成功",
            requestBody: map[string]string{
                "email":    "test@example.com",
                "code":     "654321",
                "password": "123456",
                "nickname": "邮箱用户",
            },
            expectedStatus: http.StatusOK,
            expectedCode:   200,
        },
        {
            name: "邮箱格式错误",
            requestBody: map[string]string{
                "email":    "not-an-email",
                "code":     "654321",
                "password": "123456",
            },
            expectedStatus: http.StatusBadRequest,
            expectedCode:   400,
        },
        {
            name: "密码包含字母",
            requestBody: map[string]string{
                "email":    "test2@example.com",
                "code":     "654321",
                "password": "12345a",
            },
            expectedStatus: http.StatusBadRequest,
            expectedCode:   400,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(tt.requestBody)
            req, _ := http.NewRequest("POST", "/api/auth/register/email", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)
        })
    }
}

func TestSendCode(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)

    tests := []struct {
        name           string
        requestBody    map[string]string
        expectedStatus int
    }{
        {
            name: "发送手机验证码",
            requestBody: map[string]string{
                "target": "13800138000",
                "type":   "register",
            },
            expectedStatus: http.StatusOK,
        },
        {
            name: "发送邮件验证码",
            requestBody: map[string]string{
                "target": "test@example.com",
                "type":   "register",
            },
            expectedStatus: http.StatusOK,
        },
        {
            name: "无效的类型",
            requestBody: map[string]string{
                "target": "13800138000",
                "type":   "invalid_type",
            },
            expectedStatus: http.StatusBadRequest,
        },
        {
            name: "手机号格式错误",
            requestBody: map[string]string{
                "target": "12345",
                "type":   "register",
            },
            expectedStatus: http.StatusBadRequest,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(tt.requestBody)
            req, _ := http.NewRequest("POST", "/api/auth/send-code", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)
        })
    }
}

func TestResetPassword(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)

    // 创建测试用户
    phone := "13800138000"
    createUser(db, "testuser", &phone, nil, "123456")

    // 创建验证码
    createTestVerificationCode(db, "13800138000", "123456", "reset_password")

    tests := []struct {
        name           string
        requestBody    map[string]string
        expectedStatus int
    }{
        {
            name: "重置密码成功",
            requestBody: map[string]string{
                "account":      "13800138000",
                "code":         "123456",
                "new_password": "654321",
            },
            expectedStatus: http.StatusOK,
        },
        {
            name: "验证码错误",
            requestBody: map[string]string{
                "account":      "13800138000",
                "code":         "999999",
                "new_password": "654321",
            },
            expectedStatus: http.StatusBadRequest,
        },
        {
            name: "新密码格式错误",
            requestBody: map[string]string{
                "account":      "13800138000",
                "code":         "123456",
                "new_password": "12345",
            },
            expectedStatus: http.StatusBadRequest,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(tt.requestBody)
            req, _ := http.NewRequest("POST", "/api/auth/reset-password", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)
        })
    }
}

func TestLogin(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)

    // 创建测试用户
    phone := "13800138000"
    email := "test@example.com"
    createUser(db, "testuser", &phone, &email, "123456")

    tests := []struct {
        name           string
        requestBody    map[string]string
        expectedStatus int
    }{
        {
            name: "手机号登录成功",
            requestBody: map[string]string{
                "account":  "13800138000",
                "password": "123456",
            },
            expectedStatus: http.StatusOK,
        },
        {
            name: "邮箱登录成功",
            requestBody: map[string]string{
                "account":  "test@example.com",
                "password": "123456",
            },
            expectedStatus: http.StatusOK,
        },
        {
            name: "用户名登录成功",
            requestBody: map[string]string{
                "account":  "testuser",
                "password": "123456",
            },
            expectedStatus: http.StatusOK,
        },
        {
            name: "密码错误",
            requestBody: map[string]string{
                "account":  "13800138000",
                "password": "654321",
            },
            expectedStatus: http.StatusUnauthorized,
        },
        {
            name: "账号不存在",
            requestBody: map[string]string{
                "account":  "nonexistent",
                "password": "123456",
            },
            expectedStatus: http.StatusUnauthorized,
        },
        {
            name: "密码格式错误",
            requestBody: map[string]string{
                "account":  "13800138000",
                "password": "12345",
            },
            expectedStatus: http.StatusBadRequest,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(tt.requestBody)
            req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)
        })
    }
}
```

**笔记处理器测试 (`handlers/note_test.go`)：**
```go
package handlers

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestCreateNote(t *testing.T) {
    tests := []struct {
        name           string
        setupAuth      bool
        requestBody    map[string]interface{}
        expectedStatus int
    }{
        {
            name:      "创建笔记成功",
            setupAuth: true,
            requestBody: map[string]interface{}{
                "title":     "测试笔记",
                "content":   "这是测试内容",
                "folder_id": 1,
            },
            expectedStatus: 200,
        },
        {
            name:           "未认证用户",
            setupAuth:      false,
            requestBody:    map[string]interface{}{"title": "测试"},
            expectedStatus: 401,
        },
        {
            name:           "标题为空",
            setupAuth:      true,
            requestBody:    map[string]interface{}{"content": "内容"},
            expectedStatus: 400,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // 测试逻辑
        })
    }
}

func TestGetNotes(t *testing.T) {
    // 测试获取笔记列表
}

func TestGetNoteByID(t *testing.T) {
    // 测试获取单个笔记
}

func TestUpdateNote(t *testing.T) {
    // 测试更新笔记
}

func TestDeleteNote(t *testing.T) {
    // 测试删除笔记
}
```

**目录处理器测试 (`handlers/folder_test.go`)：**
```go
package handlers

import "testing"

func TestCreateFolder(t *testing.T) {
    // 测试创建目录
}

func TestGetFolders(t *testing.T) {
    // 测试获取目录列表
}

func TestDeleteFolder(t *testing.T) {
    // 测试删除目录
}
```

**JWT中间件测试 (`middleware/auth_test.go`)：**
```go
package middleware

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestJWTMiddleware(t *testing.T) {
    tests := []struct {
        name           string
        token          string
        expectedStatus int
    }{
        {
            name:           "有效Token",
            token:          "valid_jwt_token",
            expectedStatus: 200,
        },
        {
            name:           "无效Token",
            token:          "invalid_token",
            expectedStatus: 401,
        },
        {
            name:           "过期Token",
            token:          "expired_jwt_token",
            expectedStatus: 401,
        },
        {
            name:           "缺少Token",
            token:          "",
            expectedStatus: 401,
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // 测试逻辑
        })
    }
}
```

**测试公共配置 (`tests/setup.go`)：**
```go
package tests

import (
    "os"
    "testing"
    "gorm.io/driver/sqlite"
    "gorm.io/gorm"
)

// SetupTestDB 设置测试数据库
func SetupTestDB(t *testing.T) *gorm.DB {
    // 使用内存SQLite数据库
    db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
    if err != nil {
        t.Fatalf("Failed to connect to test database: %v", err)
    }
    
    // 迁移所有数据库表（包括用户、笔记、目录、头像、验证码）
    db.AutoMigrate(&User{}, &Note{}, &Folder{}, &Avatar{}, &VerificationCode{})
    
    return db
}

// TeardownTestDB 清理测试数据库
func TeardownTestDB(db *gorm.DB) {
    sqlDB, _ := db.DB()
    sqlDB.Close()
}

// CreateTestUser 创建测试用户
func CreateTestUser(db *gorm.DB) *User {
    user := &User{
        Username: "testuser",
        Password: "hashed_password",
        Email:    "test@example.com",
    }
    db.Create(user)
    return user
}

// SetupTestRouter 设置测试路由
func SetupTestRouter(db *gorm.DB) *gin.Engine {
    gin.SetMode(gin.TestMode)
    router := gin.New()
    // 配置路由
    return router
}
```

#### 1.2 集成测试

**集成测试文件：**

```go
// tests/auth_test.go
package tests

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestAuthIntegration(t *testing.T) {
    // 设置测试环境
    db := SetupTestDB(t)
    defer TeardownTestDB(db)
    router := SetupTestRouter(db)

    t.Run("手机号注册登录完整流程", func(t *testing.T) {
        // 0. 发送验证码
        sendCodeBody := map[string]string{
            "target": "13800138000",
            "type":   "register",
        }
        body, _ := json.Marshal(sendCodeBody)
        req, _ := http.NewRequest("POST", "/api/auth/send-code", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
        assert.Equal(t, 200, w.Code)

        // 1. 手机号注册（使用测试验证码）
        registerBody := map[string]string{
            "phone":    "13800138000",
            "code":     "123456",  // 测试环境固定验证码
            "password": "123456",
            "nickname": "集成测试用户",
        }
        body, _ = json.Marshal(registerBody)
        req, _ = http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w = httptest.NewRecorder()
        router.ServeHTTP(w, req)

        assert.Equal(t, 200, w.Code)

        var regResponse map[string]interface{}
        json.Unmarshal(w.Body.Bytes(), &regResponse)
        assert.NotEmpty(t, regResponse["data"].(map[string]interface{})["token"])

        // 2. 使用手机号登录
        loginBody := map[string]string{
            "account":  "13800138000",
            "password": "123456",
        }
        body, _ = json.Marshal(loginBody)
        req, _ = http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w = httptest.NewRecorder()
        router.ServeHTTP(w, req)

        assert.Equal(t, 200, w.Code)

        var response map[string]interface{}
        json.Unmarshal(w.Body.Bytes(), &response)
        assert.NotEmpty(t, response["data"].(map[string]interface{})["token"])
    })

    t.Run("邮箱注册登录完整流程", func(t *testing.T) {
        // 1. 邮箱注册
        registerBody := map[string]string{
            "email":    "integration@test.com",
            "code":     "654321",
            "password": "123456",
            "nickname": "邮箱测试用户",
        }
        body, _ := json.Marshal(registerBody)
        req, _ := http.NewRequest("POST", "/api/auth/register/email", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
        assert.Equal(t, 200, w.Code)

        // 2. 使用邮箱登录
        loginBody := map[string]string{
            "account":  "integration@test.com",
            "password": "123456",
        }
        body, _ = json.Marshal(loginBody)
        req, _ = http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w = httptest.NewRecorder()
        router.ServeHTTP(w, req)
        assert.Equal(t, 200, w.Code)
    })

    t.Run("忘记密码重置流程", func(t *testing.T) {
        // 1. 发送重置验证码
        sendCodeBody := map[string]string{
            "target": "13800138000",
            "type":   "reset_password",
        }
        body, _ := json.Marshal(sendCodeBody)
        req, _ := http.NewRequest("POST", "/api/auth/send-code", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
        assert.Equal(t, 200, w.Code)

        // 2. 重置密码
        resetBody := map[string]string{
            "account":      "13800138000",
            "code":         "123456",
            "new_password": "654321",
        }
        body, _ = json.Marshal(resetBody)
        req, _ = http.NewRequest("POST", "/api/auth/reset-password", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w = httptest.NewRecorder()
        router.ServeHTTP(w, req)
        assert.Equal(t, 200, w.Code)

        // 3. 使用新密码登录
        loginBody := map[string]string{
            "account":  "13800138000",
            "password": "654321",
        }
        body, _ = json.Marshal(loginBody)
        req, _ = http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")

        w = httptest.NewRecorder()
        router.ServeHTTP(w, req)
        assert.Equal(t, 200, w.Code)
    })
}
```

**运行测试命令：**

```bash
# 运行所有测试
go test ./...

# 运行特定包的测试
go test ./handlers -v

# 运行带覆盖率报告的测试
go test ./... -cover -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html

# 运行测试并显示详细信息
go test -v ./...

# 只运行特定测试
go test -run TestRegister ./handlers
```

#### 1.3 用户认证处理器代码示例（6位数字密码验证）

**密码验证工具 (`utils/password.go`)：**
```go
package utils

import (
    "errors"
    "regexp"
    "golang.org/x/crypto/bcrypt"
)

// ValidatePassword 验证密码是否为6位数字
func ValidatePassword(password string) error {
    if len(password) != 6 {
        return errors.New("密码必须为6位数字")
    }

    matched, _ := regexp.MatchString(`^\d{6}$`, password)
    if !matched {
        return errors.New("密码只能包含数字")
    }

    return nil
}

// HashPassword 对密码进行bcrypt加密
func HashPassword(password string) (string, error) {
    if err := ValidatePassword(password); err != nil {
        return "", err
    }

    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(bytes), err
}

// CheckPassword 校验密码
func CheckPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
```

**手机号验证工具 (`utils/phone.go`)：**
```go
package utils

import (
    "fmt"
    "math/rand"
    "regexp"
    "time"
)

var phoneRegex = regexp.MustCompile(`^1[3-9]\d{9}$`)

// ValidatePhone 验证中国大陆手机号格式
func ValidatePhone(phone string) bool {
    return phoneRegex.MatchString(phone)
}

// MaskPhone 手机号脱敏显示（138****8000）
func MaskPhone(phone string) string {
    if len(phone) != 11 {
        return phone
    }
    return phone[:3] + "****" + phone[7:]
}

// GenerateUsername 根据手机号/邮箱生成用户名
func GenerateUsername(account string) string {
    rand.Seed(time.Now().UnixNano())
    suffix := fmt.Sprintf("%04d", rand.Intn(10000))

    if ValidatePhone(account) {
        // 手机号：使用后4位+随机数
        return "u_" + account[7:] + suffix
    }
    // 邮箱：使用@前缀+随机数
    parts := regexp.MustCompile(`@`).Split(account, 2)
    if len(parts[0]) > 8 {
        return "u_" + parts[0][:8] + suffix
    }
    return "u_" + parts[0] + suffix
}
```

**验证码工具 (`utils/verification.go`)：**
```go
package utils

import (
    "math/rand"
    "time"

    "your-app/database"
    "your-app/models"
)

// GenerateCode 生成6位数字验证码
func GenerateCode() string {
    rand.Seed(time.Now().UnixNano())
    return fmt.Sprintf("%06d", rand.Intn(1000000))
}

// CreateVerificationCode 创建验证码记录
func CreateVerificationCode(target, codeType string) (string, error) {
    code := GenerateCode()
    record := models.VerificationCode{
        Target:    target,
        Code:      code,
        Type:      codeType,
        ExpiresAt: time.Now().Add(5 * time.Minute),
        Used:      false,
    }

    if err := database.DB.Create(&record).Error; err != nil {
        return "", err
    }
    return code, nil
}

// VerifyCode 验证验证码
func VerifyCode(target, code, codeType string) bool {
    var record models.VerificationCode
    err := database.DB.Where(
        "target = ? AND code = ? AND type = ? AND used = ? AND expires_at > ?",
        target, code, codeType, false, time.Now(),
    ).First(&record).Error

    if err != nil {
        return false
    }

    // 标记为已使用
    database.DB.Model(&record).Update("used", true)
    return true
}

// CheckRateLimit 检查发送频率限制（60秒内不能重发）
func CheckRateLimit(target string) bool {
    var count int64
    database.DB.Model(&models.VerificationCode{}).
        Where("target = ? AND created_at > ?", target, time.Now().Add(-60*time.Second)).
        Count(&count)
    return count == 0
}

// CheckDailyLimit 检查每日发送上限（10次/天）
func CheckDailyLimit(target string) bool {
    var count int64
    today := time.Now().Format("2006-01-02")
    database.DB.Model(&models.VerificationCode{}).
        Where("target = ? AND DATE(created_at) = ?", target, today).
        Count(&count)
    return count < 10
}
```

**邮箱验证工具 (`utils/email.go`)：**
```go
package utils

import (
    "net/smtp"
    "fmt"
)

// SendEmailCode 发送邮件验证码
func SendEmailCode(email, code string) error {
    // 实际项目中应使用配置中心获取这些参数
    from := "noreply@example.com"
    password := "smtp_password"
    host := "smtp.example.com"
    port := "587"

    subject := "【个人笔记】您的验证码"
    body := fmt.Sprintf(`
        <html>
        <body>
            <h2>您的验证码</h2>
            <p>验证码：<strong style="font-size: 24px; color: #1890ff;">%s</strong></p>
            <p>有效期：5分钟</p>
            <p>如非本人操作，请忽略此邮件。</p>
        </body>
        </html>
    `, code)

    message := fmt.Sprintf(
        "From: %s\r\nTo: %s\r\nSubject: %s\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n%s",
        from, email, subject, body,
    )

    auth := smtp.PlainAuth("", from, password, host)
    addr := host + ":" + port
    return smtp.SendMail(addr, auth, from, []string{email}, []byte(message))
}
```

**短信发送工具 (`utils/sms.go`)：**
```go
package utils

import (
    "fmt"
    // 实际项目导入短信服务商SDK
    // "github.com/aliyun/dysmsapi20170525"
)

// SendSmsCode 发送短信验证码
func SendSmsCode(phone, code string) error {
    // 实际项目中调用短信服务商API
    // 这里使用阿里云短信作为示例
    /*
    client, _ := dysmsapi.NewClient(&openapi.Config{
        AccessKeyId:     tea.String("your-access-key-id"),
        AccessKeySecret: tea.String("your-access-key-secret"),
        Endpoint:        tea.String("dysmsapi.aliyuncs.com"),
    })

    request := &dysmsapi.SendSmsRequest{
        PhoneNumbers:  tea.String(phone),
        SignName:      tea.String("个人笔记"),
        TemplateCode:  tea.String("SMS_123456"),
        TemplateParam: tea.String(fmt.Sprintf(`{"code":"%s"}`, code)),
    }

    _, err := client.SendSms(request)
    return err
    */

    // 开发环境：直接打印验证码
    fmt.Printf("[SMS] 发送到 %s 的验证码: %s\n", phone, code)
    return nil
}
```

**utils 层单元测试 (`utils/password_test.go`)：**
```go
package utils

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestValidatePassword(t *testing.T) {
    tests := []struct {
        name     string
        password string
        valid    bool
    }{
        {"6位数字-有效", "123456", true},
        {"6位数字-全0", "000000", true},
        {"6位数字-全9", "999999", true},
        {"5位数字-无效", "12345", false},
        {"7位数字-无效", "1234567", false},
        {"包含字母-无效", "12345a", false},
        {"全字母-无效", "abcdef", false},
        {"包含特殊字符-无效", "12345!", false},
        {"空字符串-无效", "", false},
        {"带空格-无效", "12345 ", false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidatePassword(tt.password)
            if tt.valid {
                assert.NoError(t, err)
            } else {
                assert.Error(t, err)
            }
        })
    }
}

func TestHashAndCheckPassword(t *testing.T) {
    password := "123456"
    hash, err := HashPassword(password)
    assert.NoError(t, err)
    assert.NotEmpty(t, hash)

    // 正确密码
    assert.True(t, CheckPassword(password, hash))
    // 错误密码
    assert.False(t, CheckPassword("654321", hash))
}
```

**utils 层单元测试 (`utils/phone_test.go`)：**
```go
package utils

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestValidatePhone(t *testing.T) {
    tests := []struct {
        name  string
        phone string
        valid bool
    }{
        {"有效-138", "13800138000", true},
        {"有效-159", "15912345678", true},
        {"有效-186", "18612345678", true},
        {"无效-123开头", "12345678901", false},
        {"无效-11位但1[0-2]", "12012345678", false},
        {"无效-10位", "1380013800", false},
        {"无效-12位", "138001380000", false},
        {"无效-字母", "abc12345678", false},
        {"无效-空", "", false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := ValidatePhone(tt.phone)
            assert.Equal(t, tt.valid, result)
        })
    }
}

func TestMaskPhone(t *testing.T) {
    assert.Equal(t, "138****8000", MaskPhone("13800138000"))
    assert.Equal(t, "159****5678", MaskPhone("15912345678"))
    assert.Equal(t, "invalid", MaskPhone("invalid"))  // 非手机号不处理
}

func TestGenerateUsername(t *testing.T) {
    // 手机号生成
    username := GenerateUsername("13800138000")
    assert.Contains(t, username, "8000")
    assert.HasPrefix(t, username, "u_")

    // 邮箱生成
    username = GenerateUsername("test@example.com")
    assert.Contains(t, username, "test")
    assert.HasPrefix(t, username, "u_")
}
```

**注册处理器示例 (`handlers/auth.go`)：**
```go
package handlers

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "your-app/models"
    "your-app/utils"
    "your-app/database"
)

type RegisterByPhoneRequest struct {
    Phone    string `json:"phone" binding:"required"`
    Code     string `json:"code" binding:"required,len=6"`
    Password string `json:"password" binding:"required"`
    Nickname string `json:"nickname"`
}

type RegisterByEmailRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Code     string `json:"code" binding:"required,len=6"`
    Password string `json:"password" binding:"required"`
    Nickname string `json:"nickname"`
}

// RegisterByPhone 手机号注册
func RegisterByPhone(c *gin.Context) {
    var req RegisterByPhoneRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请求参数错误: " + err.Error(),
        })
        return
    }

    // 验证密码是6位数字
    if err := utils.ValidatePassword(req.Password); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": err.Error(),
        })
        return
    }

    // 验证手机号格式
    if !utils.ValidatePhone(req.Phone) {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "手机号格式错误",
        })
        return
    }

    // 验证短信验证码
    if !utils.VerifyCode(req.Phone, req.Code, "register") {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "验证码错误或已过期",
        })
        return
    }

    // 检查手机号是否已注册
    var existingUser models.User
    if err := database.DB.Where("phone = ?", req.Phone).First(&existingUser).Error; err == nil {
        c.JSON(http.StatusConflict, gin.H{
            "code": 409,
            "message": "该手机号已注册",
        })
        return
    }

    // 加密密码
    hashedPassword, err := utils.HashPassword(req.Password)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "密码加密失败",
        })
        return
    }

    // 生成用户名（使用手机号后四位+随机数）
    username := utils.GenerateUsername(req.Phone)

    // 创建用户
    user := models.User{
        Username: username,
        Phone:    &req.Phone,
        Password: hashedPassword,
        Nickname: req.Nickname,
    }

    if err := database.DB.Create(&user).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "注册失败",
        })
        return
    }

    // 生成JWT Token
    token, err := utils.GenerateToken(user.ID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "生成Token失败",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "注册成功",
        "data": gin.H{
            "user_id": user.ID,
            "token":   token,
            "user":    user.ToResponse(),
        },
    })
}

// RegisterByEmail 邮箱注册
func RegisterByEmail(c *gin.Context) {
    var req RegisterByEmailRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请求参数错误: " + err.Error(),
        })
        return
    }

    // 验证密码是6位数字
    if err := utils.ValidatePassword(req.Password); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": err.Error(),
        })
        return
    }

    // 验证邮箱验证码
    if !utils.VerifyCode(req.Email, req.Code, "register") {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "验证码错误或已过期",
        })
        return
    }

    // 检查邮箱是否已注册
    var existingUser models.User
    if err := database.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
        c.JSON(http.StatusConflict, gin.H{
            "code": 409,
            "message": "该邮箱已注册",
        })
        return
    }

    hashedPassword, err := utils.HashPassword(req.Password)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "密码加密失败",
        })
        return
    }

    username := utils.GenerateUsername(req.Email)

    user := models.User{
        Username: username,
        Email:    &req.Email,
        Password: hashedPassword,
        Nickname: req.Nickname,
    }

    if err := database.DB.Create(&user).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "注册失败",
        })
        return
    }

    token, _ := utils.GenerateToken(user.ID)

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "注册成功",
        "data": gin.H{
            "user_id": user.ID,
            "token":   token,
            "user":    user.ToResponse(),
        },
    })
}

// Login 登录（支持手机号/邮箱/用户名）
func Login(c *gin.Context) {
    var req struct {
        Account  string `json:"account" binding:"required"`
        Password string `json:"password" binding:"required"`
    }

    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请求参数错误",
        })
        return
    }

    // 验证密码是6位数字
    if err := utils.ValidatePassword(req.Password); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": err.Error(),
        })
        return
    }

    // 查找用户（支持手机号/邮箱/用户名）
    var user models.User
    result := database.DB.Where("phone = ? OR email = ? OR username = ?",
        req.Account, req.Account, req.Account).First(&user)

    if result.Error != nil {
        c.JSON(http.StatusUnauthorized, gin.H{
            "code": 401,
            "message": "账号或密码错误",
        })
        return
    }

    // 验证密码
    if !utils.CheckPassword(req.Password, user.Password) {
        c.JSON(http.StatusUnauthorized, gin.H{
            "code": 401,
            "message": "账号或密码错误",
        })
        return
    }

    token, _ := utils.GenerateToken(user.ID)

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "登录成功",
        "data": gin.H{
            "token": token,
            "user":  user.ToResponse(),
        },
    })
}
```

#### 1.4 个人信息处理器代码示例

**个人信息处理器 (`handlers/profile.go`)：**
```go
package handlers

import (
    "net/http"
    "path/filepath"
    "strconv"
    "time"

    "github.com/gin-gonic/gin"
    "your-app/database"
    "your-app/models"
    "your-app/utils"
)

// GetProfile 获取个人信息
func GetProfile(c *gin.Context) {
    userID := c.GetUint("user_id")

    var user models.User
    if err := database.DB.First(&user, userID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "code": 404,
            "message": "用户不存在",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "data": user.ToResponse(),
    })
}

// UpdateNickname 修改昵称
func UpdateNickname(c *gin.Context) {
    userID := c.GetUint("user_id")

    var req struct {
        Nickname string `json:"nickname" binding:"required,min=1,max=50"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "昵称长度应在1-50个字符之间",
        })
        return
    }

    if err := database.DB.Model(&models.User{}).
        Where("id = ?", userID).
        Update("nickname", req.Nickname).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "修改失败",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "修改成功",
        "data": gin.H{"nickname": req.Nickname},
    })
}

// UpdateAvatar 修改头像（上传图片）
func UpdateAvatar(c *gin.Context) {
    userID := c.GetUint("user_id")

    // 获取上传的文件
    file, err := c.FormFile("avatar")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请选择头像文件",
        })
        return
    }

    // 验证文件类型
    ext := filepath.Ext(file.Filename)
    allowedExts := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".gif": true}
    if !allowedExts[ext] {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "只支持 jpg、jpeg、png、gif 格式的图片",
        })
        return
    }

    // 验证文件大小（最大5MB）
    if file.Size > 5*1024*1024 {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "头像大小不能超过5MB",
        })
        return
    }

    // 生成唯一文件名
    filename := strconv.FormatUint(uint64(userID), 10) + "_" +
        strconv.FormatInt(time.Now().UnixNano(), 10) + ext
    savePath := filepath.Join("uploads", "avatars", filename)

    // 保存文件
    if err := c.SaveUploadedFile(file, savePath); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "文件保存失败",
        })
        return
    }

    // 生成访问URL
    avatarURL := "/uploads/avatars/" + filename

    // 更新数据库
    if err := database.DB.Model(&models.User{}).
        Where("id = ?", userID).
        Update("avatar_url", avatarURL).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "更新失败",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "头像上传成功",
        "data": gin.H{"avatar_url": avatarURL},
    })
}

// UpdateBirthday 修改生日
func UpdateBirthday(c *gin.Context) {
    userID := c.GetUint("user_id")

    var req struct {
        Birthday string `json:"birthday" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请提供有效的生日日期",
        })
        return
    }

    // 验证日期格式
    birthday, err := time.Parse("2006-01-02", req.Birthday)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "日期格式错误，应为 YYYY-MM-DD",
        })
        return
    }

    // 验证生日不能在未来
    if birthday.After(time.Now()) {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "生日不能在未来",
        })
        return
    }

    if err := database.DB.Model(&models.User{}).
        Where("id = ?", userID).
        Update("birthday", birthday).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "修改失败",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "修改成功",
        "data": gin.H{"birthday": req.Birthday},
    })
}

// UpdatePhone 修改手机号（需验证码）
func UpdatePhone(c *gin.Context) {
    userID := c.GetUint("user_id")

    var req struct {
        Phone string `json:"phone" binding:"required"`
        Code  string `json:"code" binding:"required,len=6"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请求参数错误",
        })
        return
    }

    // 验证手机号格式
    if !utils.ValidatePhone(req.Phone) {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "手机号格式错误",
        })
        return
    }

    // 验证短信验证码
    if !utils.VerifyCode(req.Phone, req.Code, "verify_phone") {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "验证码错误或已过期",
        })
        return
    }

    // 检查手机号是否被其他用户使用
    var existingUser models.User
    if err := database.DB.Where("phone = ? AND id != ?", req.Phone, userID).
        First(&existingUser).Error; err == nil {
        c.JSON(http.StatusConflict, gin.H{
            "code": 409,
            "message": "该手机号已被其他用户使用",
        })
        return
    }

    if err := database.DB.Model(&models.User{}).
        Where("id = ?", userID).
        Update("phone", req.Phone).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "修改失败",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "手机号修改成功",
    })
}

// UpdateEmail 修改邮箱（需验证码）
func UpdateEmail(c *gin.Context) {
    userID := c.GetUint("user_id")

    var req struct {
        Email string `json:"email" binding:"required,email"`
        Code  string `json:"code" binding:"required,len=6"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请求参数错误",
        })
        return
    }

    // 验证邮箱验证码
    if !utils.VerifyCode(req.Email, req.Code, "verify_email") {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "验证码错误或已过期",
        })
        return
    }

    // 检查邮箱是否被其他用户使用
    var existingUser models.User
    if err := database.DB.Where("email = ? AND id != ?", req.Email, userID).
        First(&existingUser).Error; err == nil {
        c.JSON(http.StatusConflict, gin.H{
            "code": 409,
            "message": "该邮箱已被其他用户使用",
        })
        return
    }

    if err := database.DB.Model(&models.User{}).
        Where("id = ?", userID).
        Update("email", req.Email).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "修改失败",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "邮箱修改成功",
    })
}

// UpdatePassword 修改密码（需验证旧密码）
func UpdatePassword(c *gin.Context) {
    userID := c.GetUint("user_id")

    var req struct {
        OldPassword string `json:"old_password" binding:"required"`
        NewPassword string `json:"new_password" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "请求参数错误",
        })
        return
    }

    // 验证新密码是6位数字
    if err := utils.ValidatePassword(req.NewPassword); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": err.Error(),
        })
        return
    }

    // 获取当前用户
    var user models.User
    if err := database.DB.First(&user, userID).Error; err != nil {
        c.JSON(http.StatusNotFound, gin.H{
            "code": 404,
            "message": "用户不存在",
        })
        return
    }

    // 验证旧密码
    if !utils.CheckPassword(req.OldPassword, user.Password) {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "旧密码错误",
        })
        return
    }

    // 新旧密码不能相同
    if req.OldPassword == req.NewPassword {
        c.JSON(http.StatusBadRequest, gin.H{
            "code": 400,
            "message": "新密码不能与旧密码相同",
        })
        return
    }

    // 加密新密码
    hashedPassword, err := utils.HashPassword(req.NewPassword)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "密码加密失败",
        })
        return
    }

    if err := database.DB.Model(&models.User{}).
        Where("id = ?", userID).
        Update("password", hashedPassword).Error; err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "code": 500,
            "message": "密码修改失败",
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "code": 200,
        "message": "密码修改成功",
    })
}
```

#### 1.5 个人信息单元测试示例

**个人信息测试 (`handlers/profile_test.go`)：**
```go
package handlers

import (
    "bytes"
    "encoding/json"
    "mime/multipart"
    "net/http"
    "net/http/httptest"
    "os"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/gin-gonic/gin"
)

func TestGetProfile(t *testing.T) {
    gin.SetMode(gin.TestMode)

    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)

    // 创建测试用户
    user := createTestUser(db, "testuser", "13800138000")
    token := generateTestToken(user.ID)

    req, _ := http.NewRequest("GET", "/api/profile", nil)
    req.Header.Set("Authorization", "Bearer "+token)

    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    assert.Equal(t, 200, w.Code)

    var response map[string]interface{}
    json.Unmarshal(w.Body.Bytes(), &response)
    assert.Equal(t, float64(200), response["code"])

    data := response["data"].(map[string]interface{})
    assert.Equal(t, "testuser", data["username"])
}

func TestUpdateNickname(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)
    user := createTestUser(db, "testuser", "13800138000")
    token := generateTestToken(user.ID)

    tests := []struct {
        name           string
        nickname       string
        expectedStatus int
        expectedCode   int
    }{
        {
            name:           "正常修改昵称",
            nickname:       "新昵称",
            expectedStatus: 200,
            expectedCode:   200,
        },
        {
            name:           "昵称为空",
            nickname:       "",
            expectedStatus: 400,
            expectedCode:   400,
        },
        {
            name:           "昵称过长",
            nickname:       string(make([]byte, 100)),
            expectedStatus: 400,
            expectedCode:   400,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(map[string]string{"nickname": tt.nickname})
            req, _ := http.NewRequest("PUT", "/api/profile/nickname", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")
            req.Header.Set("Authorization", "Bearer "+token)

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)
        })
    }
}

func TestUpdateBirthday(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)
    user := createTestUser(db, "testuser", "13800138000")
    token := generateTestToken(user.ID)

    tests := []struct {
        name           string
        birthday       string
        expectedStatus int
    }{
        {
            name:           "正常修改生日",
            birthday:       "1995-06-15",
            expectedStatus: 200,
        },
        {
            name:           "日期格式错误",
            birthday:       "1995/06/15",
            expectedStatus: 400,
        },
        {
            name:           "生日在未来",
            birthday:       "2099-01-01",
            expectedStatus: 400,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(map[string]string{"birthday": tt.birthday})
            req, _ := http.NewRequest("PUT", "/api/profile/birthday", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")
            req.Header.Set("Authorization", "Bearer "+token)

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)
        })
    }
}

func TestUpdateAvatar(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)
    user := createTestUser(db, "testuser", "13800138000")
    token := generateTestToken(user.ID)

    // 创建测试图片文件
    body := &bytes.Buffer{}
    writer := multipart.NewWriter(body)
    part, _ := writer.CreateFormFile("avatar", "test.jpg")
    part.Write([]byte("fake image content"))
    writer.Close()

    req, _ := http.NewRequest("POST", "/api/profile/avatar", body)
    req.Header.Set("Content-Type", writer.FormDataContentType())
    req.Header.Set("Authorization", "Bearer "+token)

    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)

    assert.Equal(t, 200, w.Code)
}

func TestUpdatePassword(t *testing.T) {
    gin.SetMode(gin.TestMode)
    db := setupTestDB(t)
    defer teardownTestDB(db)
    router := setupTestRouter(db)
    user := createTestUserWithPassword(db, "testuser", "13800138000", "123456")
    token := generateTestToken(user.ID)

    tests := []struct {
        name           string
        oldPassword    string
        newPassword    string
        expectedStatus int
    }{
        {
            name:           "正常修改密码",
            oldPassword:    "123456",
            newPassword:    "654321",
            expectedStatus: 200,
        },
        {
            name:           "旧密码错误",
            oldPassword:    "111111",
            newPassword:    "654321",
            expectedStatus: 400,
        },
        {
            name:           "新密码不是6位数字",
            oldPassword:    "123456",
            newPassword:    "12345",
            expectedStatus: 400,
        },
        {
            name:           "新密码包含字母",
            oldPassword:    "123456",
            newPassword:    "12345a",
            expectedStatus: 400,
        },
        {
            name:           "新旧密码相同",
            oldPassword:    "123456",
            newPassword:    "123456",
            expectedStatus: 400,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            body, _ := json.Marshal(map[string]string{
                "old_password": tt.oldPassword,
                "new_password": tt.newPassword,
            })
            req, _ := http.NewRequest("PUT", "/api/profile/password", bytes.NewBuffer(body))
            req.Header.Set("Content-Type", "application/json")
            req.Header.Set("Authorization", "Bearer "+token)

            w := httptest.NewRecorder()
            router.ServeHTTP(w, req)

            assert.Equal(t, tt.expectedStatus, w.Code)
        })
    }
}

func TestPasswordValidation(t *testing.T) {
    tests := []struct {
        name     string
        password string
        valid    bool
    }{
        {"6位数字-有效", "123456", true},
        {"6位数字-全0", "000000", true},
        {"5位数字-无效", "12345", false},
        {"7位数字-无效", "1234567", false},
        {"包含字母-无效", "12345a", false},
        {"空密码-无效", "", false},
        {"特殊字符-无效", "12345!", false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := utils.ValidatePassword(tt.password)
            if tt.valid {
                assert.NoError(t, err)
            } else {
                assert.Error(t, err)
            }
        })
    }
}

// 辅助函数
func createTestUserWithPassword(db *gorm.DB, username, phone, password string) *models.User {
    hashedPassword, _ := utils.HashPassword(password)
    user := &models.User{
        Username: username,
        Phone:    &phone,
        Password: hashedPassword,
    }
    db.Create(user)
    return user
}
```

**测试覆盖率目标：**
- 处理器层：≥ 80%
- 中间件层：≥ 90%
- 模型层：≥ 70%
- 总体覆盖率：≥ 80%

---

### 二、Web端测试 (JavaScript)

#### 2.1 测试框架

**技术选型：**
- Jest (测试框架)
- jsdom (DOM模拟)
- fetch-mock (API mock)

**项目结构：**
```
web/
├── __tests__/
│   ├── auth.test.js           # 认证功能测试
│   ├── notes.test.js          # 笔记功能测试
│   ├── folders.test.js        # 目录功能测试
│   ├── profile.test.js        # 个人信息测试
│   └── api.test.js           # API调用测试
├── js/
│   ├── auth.js
│   ├── notes.js
│   ├── folders.js
│   ├── profile.js
│   └── api.js
└── package.json
```

**认证测试示例 (`__tests__/auth.test.js`)：**
```javascript
describe('认证功能测试', () => {
    beforeEach(() => {
        document.body.innerHTML = `
            <form id="loginForm">
                <input id="username" type="text" />
                <input id="password" type="password" />
                <button type="submit">登录</button>
            </form>
        `;
        localStorage.clear();
    });

    test('用户登录成功', async () => {
        // Mock API响应
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: true,
                json: () => Promise.resolve({
                    code: 200,
                    data: {
                        token: 'test_token',
                        user: { id: 1, username: 'testuser' }
                    }
                })
            })
        );

        // 模拟用户输入
        document.getElementById('username').value = 'testuser';
        document.getElementById('password').value = '123456';

        // 触发登录
        await login();

        // 验证token已存储
        expect(localStorage.getItem('token')).toBe('test_token');
    });

    test('用户登录失败 - 错误密码', async () => {
        // Mock API响应
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: false,
                json: () => Promise.resolve({
                    code: 401,
                    message: '用户名或密码错误'
                })
            })
        );

        // 模拟用户输入
        document.getElementById('username').value = 'testuser';
        document.getElementById('password').value = '654321';

        // 触发登录
        const result = await login();

        // 验证错误信息
        expect(result.success).toBe(false);
        expect(localStorage.getItem('token')).toBeNull();
    });

    test('Token自动刷新', () => {
        // 测试token过期自动刷新逻辑
    });
});
```

**笔记功能测试 (`__tests__/notes.test.js`)：**
```javascript
describe('笔记功能测试', () => {
    beforeEach(() => {
        localStorage.setItem('token', 'test_token');
    });

    test('创建笔记', async () => {
        const noteData = {
            title: '测试笔记',
            content: '测试内容',
            folder_id: 1
        };

        const result = await createNote(noteData);

        expect(result.success).toBe(true);
        expect(result.data.note_id).toBeDefined();
    });

    test('获取笔记列表', async () => {
        const notes = await getNotes();

        expect(Array.isArray(notes)).toBe(true);
        expect(notes.length).toBeGreaterThan(0);
    });

    test('更新笔记', async () => {
        const noteId = 1;
        const updateData = {
            title: '更新后的标题',
            content: '更新后的内容'
        };

        const result = await updateNote(noteId, updateData);

        expect(result.success).toBe(true);
    });

    test('删除笔记', async () => {
        const noteId = 1;
        const result = await deleteNote(noteId);

        expect(result.success).toBe(true);
    });

    test('笔记标题不能为空', async () => {
        const noteData = {
            title: '',
            content: '内容'
        };

        const result = await createNote(noteData);

        expect(result.success).toBe(false);
        expect(result.error).toContain('标题不能为空');
    });
});
```

**目录功能测试 (`__tests__/folders.test.js`)：**
```javascript
describe('目录功能测试', () => {
    test('创建目录', async () => {
        const folderData = { name: '新目录' };
        const result = await createFolder(folderData);

        expect(result.success).toBe(true);
        expect(result.data.folder_id).toBeDefined();
    });

    test('获取目录列表', async () => {
        const folders = await getFolders();

        expect(Array.isArray(folders)).toBe(true);
    });

    test('删除目录', async () => {
        const folderId = 1;
        const result = await deleteFolder(folderId);

        expect(result.success).toBe(true);
    });
});
```

**个人信息测试 (`__tests__/profile.test.js`)：**
```javascript
describe('个人信息测试', () => {
    beforeEach(() => {
        localStorage.setItem('token', 'test_token');
    });

    test('获取个人信息', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: true,
                json: () => Promise.resolve({
                    code: 200,
                    data: {
                        id: 1,
                        username: 'testuser',
                        phone: '13800138000',
                        email: 'test@example.com',
                        nickname: '小明',
                        avatar_url: '/uploads/avatars/1.jpg',
                        birthday: '1990-01-01'
                    }
                })
            })
        );

        const profile = await getProfile();

        expect(profile.success).toBe(true);
        expect(profile.data.nickname).toBe('小明');
        expect(profile.data.phone).toBe('13800138000');
    });

    test('修改昵称', async () => {
        const result = await updateNickname('新昵称');

        expect(result.success).toBe(true);
    });

    test('昵称不能为空', async () => {
        const result = await updateNickname('');

        expect(result.success).toBe(false);
        expect(result.error).toContain('昵称不能为空');
    });

    test('修改生日', async () => {
        const result = await updateBirthday('1995-06-15');

        expect(result.success).toBe(true);
    });

    test('生日不能在未来', async () => {
        const result = await updateBirthday('2099-01-01');

        expect(result.success).toBe(false);
        expect(result.error).toContain('生日不能在未来');
    });

    test('上传头像', async () => {
        const file = new File(['fake-image'], 'avatar.jpg', { type: 'image/jpeg' });
        const result = await uploadAvatar(file);

        expect(result.success).toBe(true);
        expect(result.data.avatar_url).toBeDefined();
    });

    test('头像文件类型验证', async () => {
        const file = new File(['fake'], 'avatar.exe', { type: 'application/exe' });
        const result = await uploadAvatar(file);

        expect(result.success).toBe(false);
        expect(result.error).toContain('只支持');
    });

    test('头像大小限制（5MB）', async () => {
        const bigFile = new File([new ArrayBuffer(6 * 1024 * 1024)], 'big.jpg');
        const result = await uploadAvatar(bigFile);

        expect(result.success).toBe(false);
        expect(result.error).toContain('5MB');
    });

    test('修改手机号（需验证码）', async () => {
        const result = await updatePhone('13900139000', '123456');

        expect(result.success).toBe(true);
    });

    test('修改邮箱（需验证码）', async () => {
        const result = await updateEmail('new@example.com', '654321');

        expect(result.success).toBe(true);
    });

    test('修改密码 - 正常流程', async () => {
        const result = await changePassword('123456', '654321');

        expect(result.success).toBe(true);
    });

    test('修改密码 - 旧密码错误', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: false,
                json: () => Promise.resolve({
                    code: 400,
                    message: '旧密码错误'
                })
            })
        );

        const result = await changePassword('111111', '654321');

        expect(result.success).toBe(false);
    });

    test('修改密码 - 密码必须是6位数字', async () => {
        const result1 = await changePassword('123456', '12345');
        expect(result1.success).toBe(false);

        const result2 = await changePassword('123456', '1234567');
        expect(result2.success).toBe(false);

        const result3 = await changePassword('123456', '12345a');
        expect(result3.success).toBe(false);
    });

    test('发送验证码', async () => {
        const result = await sendVerificationCode('13800138000', 'register');

        expect(result.success).toBe(true);
        expect(result.data.expires_in).toBe(300);
    });

    test('手机号注册', async () => {
        const result = await registerByPhone({
            phone: '13800138000',
            code: '123456',
            password: '123456',
            nickname: '小明'
        });

        expect(result.success).toBe(true);
        expect(result.data.token).toBeDefined();
    });

    test('邮箱注册', async () => {
        const result = await registerByEmail({
            email: 'user@example.com',
            code: '654321',
            password: '123456',
            nickname: '小明'
        });

        expect(result.success).toBe(true);
    });
});
```

**API调用测试 (`__tests__/api.test.js`)：**
```javascript
describe('API调用测试', () => {
    test('API请求包含正确的Authorization头', async () => {
        localStorage.setItem('token', 'test_token');

        await apiCall('/api/notes');

        expect(global.fetch).toHaveBeenCalledWith(
            expect.any(String),
            expect.objectContaining({
                headers: expect.objectContaining({
                    'Authorization': 'Bearer test_token'
                })
            })
        );
    });

    test('401响应自动跳转到登录页', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: false,
                status: 401,
                json: () => Promise.resolve({ code: 401, message: '未授权' })
            })
        );

        await apiCall('/api/notes');

        expect(window.location.href).toContain('/login.html');
    });

    test('400响应 - 参数错误处理', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: false,
                status: 400,
                json: () => Promise.resolve({
                    code: 400,
                    message: '请求参数错误'
                })
            })
        );

        const result = await apiCall('/api/notes', { method: 'POST', body: {} });

        expect(result.success).toBe(false);
        expect(result.message).toBe('请求参数错误');
    });

    test('404响应 - 资源不存在处理', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: false,
                status: 404,
                json: () => Promise.resolve({
                    code: 404,
                    message: '笔记不存在'
                })
            })
        );

        const result = await apiCall('/api/notes/99999');

        expect(result.success).toBe(false);
        expect(result.message).toBe('笔记不存在');
    });

    test('409响应 - 资源冲突处理（重复注册）', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: false,
                status: 409,
                json: () => Promise.resolve({
                    code: 409,
                    message: '该手机号已注册'
                })
            })
        );

        const result = await apiCall('/api/auth/register/phone', {
            method: 'POST',
            body: { phone: '13800138000' }
        });

        expect(result.success).toBe(false);
        expect(result.message).toBe('该手机号已注册');
    });

    test('500响应 - 服务器错误处理', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: false,
                status: 500,
                json: () => Promise.resolve({
                    code: 500,
                    message: '服务器内部错误'
                })
            })
        );

        const result = await apiCall('/api/notes');

        expect(result.success).toBe(false);
        expect(result.message).toContain('服务器');
    });

    test('网络错误处理', async () => {
        global.fetch = jest.fn(() => Promise.reject(new Error('Network error')));

        const result = await apiCall('/api/notes');

        expect(result.success).toBe(false);
        expect(result.message).toContain('网络错误');
    });
});
```

**运行Web测试命令：**
```bash
# 安装依赖
cd web
npm install

# 运行所有测试
npm test

# 运行测试并生成覆盖率报告
npm test -- --coverage

# 监听模式（开发时使用）
npm test -- --watch

# 运行特定测试文件
npm test -- auth.test.js
```

#### 2.2 E2E 端到端测试

**技术选型：**
- Playwright (微软出品，支持多浏览器)
- 替代方案：Cypress / Selenium

**安装依赖：**
```bash
cd web
npm install --save-dev @playwright/test
npx playwright install
```

**项目结构：**
```
web/
├── e2e/
│   ├── auth.spec.js           # 认证流程E2E测试
│   ├── notes.spec.js          # 笔记流程E2E测试
│   ├── folders.spec.js        # 目录流程E2E测试
│   ├── full-flow.spec.js      # 完整用户流程
│   └── fixtures/
│       └── test-data.json     # 测试数据
├── playwright.config.js       # Playwright配置
└── package.json
```

**Playwright 配置 (`playwright.config.js`)：**
```javascript
// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
    testDir: './e2e',
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,
    reporter: [
        ['html'],
        ['json', { outputFile: 'test-results.json' }]
    ],

    use: {
        baseURL: 'http://localhost:5500',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
    },

    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
        {
            name: 'firefox',
            use: { ...devices['Desktop Firefox'] },
        },
        {
            name: 'webkit',
            use: { ...devices['Desktop Safari'] },
        },
        // 移动端测试
        {
            name: 'Mobile Chrome',
            use: { ...devices['Pixel 5'] },
        },
        {
            name: 'Mobile Safari',
            use: { ...devices['iPhone 13'] },
        },
    ],

    webServer: {
        command: 'npm run start',
        url: 'http://localhost:5500',
        reuseExistingServer: !process.env.CI,
    },
});
```

**认证流程E2E测试 (`e2e/auth.spec.js`)：**
```javascript
// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('认证流程 E2E 测试', () => {

    test.beforeEach(async ({ page }) => {
        // 每个测试前清除存储状态
        await page.context().clearCookies();
        await page.evaluate(() => localStorage.clear());
    });

    test('手机号注册流程', async ({ page }) => {
        await page.goto('/register.html');

        // 选择手机号注册
        await page.click('[data-register-type="phone"]');
        await expect(page.locator('#phoneInput')).toBeVisible();

        // 填写手机号
        const phone = '138' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        await page.fill('#phoneInput', phone);

        // 获取验证码
        await page.click('#sendCodeButton');
        await expect(page.locator('.code-sent-message')).toBeVisible();

        // 填写验证码（测试环境固定为 123456）
        await page.fill('#codeInput', '123456');

        // 设置6位数字密码
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');

        // 可选：填写昵称
        await page.fill('#nickname', '测试用户');

        // 点击注册按钮
        await page.click('#registerButton');

        // 等待注册成功提示
        await expect(page.locator('.success-message')).toBeVisible();

        // 验证跳转到登录页
        await expect(page).toHaveURL(/.*login\.html/);
    });

    test('邮箱注册流程', async ({ page }) => {
        await page.goto('/register.html');

        // 选择邮箱注册
        await page.click('[data-register-type="email"]');
        await expect(page.locator('#emailInput')).toBeVisible();

        // 填写邮箱
        const email = 'test_' + Date.now() + '@example.com';
        await page.fill('#emailInput', email);

        // 获取验证码
        await page.click('#sendCodeButton');
        await expect(page.locator('.code-sent-message')).toBeVisible();

        // 填写验证码
        await page.fill('#codeInput', '654321');

        // 设置6位数字密码
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');

        // 点击注册按钮
        await page.click('#registerButton');

        // 等待注册成功
        await expect(page.locator('.success-message')).toBeVisible();
        await expect(page).toHaveURL(/.*login\.html/);
    });

    test('注册失败 - 密码不是6位数字', async ({ page }) => {
        await page.goto('/register.html');

        await page.click('[data-register-type="phone"]');
        await page.fill('#phoneInput', '13800138000');
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '123456');

        // 输入非6位数字密码
        await page.fill('#password', '12345');
        await page.fill('#confirmPassword', '12345');
        await page.click('#registerButton');

        // 验证显示密码格式错误
        await expect(page.locator('#password-error')).toContainText('密码必须为6位数字');
    });

    test('注册失败 - 验证码错误', async ({ page }) => {
        await page.goto('/register.html');

        await page.click('[data-register-type="phone"]');
        await page.fill('#phoneInput', '13800138001');
        await page.click('#sendCodeButton');

        // 输入错误验证码
        await page.fill('#codeInput', '999999');
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');
        await page.click('#registerButton');

        // 验证显示验证码错误
        await expect(page.locator('.error-message')).toContainText('验证码错误');
    });

    test('用户登录流程 - 手机号登录', async ({ page }) => {
        // 先注册一个手机号用户
        await page.goto('/register.html');
        await page.click('[data-register-type="phone"]');
        const phone = '138' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        await page.fill('#phoneInput', phone);
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '123456');
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');
        await page.click('#registerButton');
        await expect(page).toHaveURL(/.*login\.html/);

        // 使用手机号登录
        await page.fill('#accountInput', phone);
        await page.fill('#passwordInput', '123456');
        await page.click('#loginButton');

        // 验证跳转到主页
        await expect(page).toHaveURL(/.*index\.html/);

        // 验证 token 已存储在 localStorage
        const token = await page.evaluate(() => localStorage.getItem('token'));
        expect(token).toBeTruthy();
    });

    test('用户登录流程 - 邮箱登录', async ({ page }) => {
        // 先注册一个邮箱用户
        await page.goto('/register.html');
        await page.click('[data-register-type="email"]');
        const email = 'login_' + Date.now() + '@example.com';
        await page.fill('#emailInput', email);
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '654321');
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');
        await page.click('#registerButton');
        await expect(page).toHaveURL(/.*login\.html/);

        // 使用邮箱登录
        await page.fill('#accountInput', email);
        await page.fill('#passwordInput', '123456');
        await page.click('#loginButton');

        await expect(page).toHaveURL(/.*index\.html/);
    });

    test('登录失败 - 错误密码', async ({ page }) => {
        await page.goto('/login.html');

        await page.fill('#accountInput', '13800138000');
        await page.fill('#passwordInput', '654321');
        await page.click('#loginButton');

        // 验证显示错误提示
        await expect(page.locator('.error-message')).toContainText(
            '账号或密码错误'
        );
    });

    test('登录失败 - 表单验证', async ({ page }) => {
        await page.goto('/login.html');

        // 不填写任何内容直接提交
        await page.click('#loginButton');

        // 验证显示验证错误
        await expect(page.locator('#account-error')).toContainText(
            '请输入手机号/邮箱/用户名'
        );
        await expect(page.locator('#password-error')).toContainText(
            '请输入密码'
        );
    });

    test('自动登出 - Token过期', async ({ page }) => {
        // 模拟过期token
        await page.goto('/login.html');
        await page.evaluate(() => {
            localStorage.setItem('token', 'expired_token');
        });

        await page.goto('/index.html');

        // 应该被重定向到登录页
        await expect(page).toHaveURL(/.*login\.html/);
    });

    test('登出功能', async ({ page }) => {
        // 先注册并登录
        await page.goto('/register.html');
        await page.click('[data-register-type="phone"]');
        const phone = '138' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        await page.fill('#phoneInput', phone);
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '123456');
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');
        await page.click('#registerButton');

        await page.goto('/login.html');
        await page.fill('#accountInput', phone);
        await page.fill('#passwordInput', '123456');
        await page.click('#loginButton');
        await expect(page).toHaveURL(/.*index\.html/);

        // 点击登出
        await page.click('#logoutButton');

        // 验证跳转到登录页并清除token
        await expect(page).toHaveURL(/.*login\.html/);
        const token = await page.evaluate(() => localStorage.getItem('token'));
        expect(token).toBeNull();
    });
        await page.click('#loginButton');
        await expect(page).toHaveURL(/.*index\.html/);

        // 点击登出
        await page.click('#logoutButton');

        // 验证跳转到登录页并清除token
        await expect(page).toHaveURL(/.*login\.html/);
        const token = await page.evaluate(() => localStorage.getItem('token'));
        expect(token).toBeNull();
    });
});
```

**笔记流程E2E测试 (`e2e/notes.spec.js`)：**
```javascript
const { test, expect } = require('@playwright/test');

test.describe('笔记管理 E2E 测试', () => {

    // 登录辅助函数
    async function login(page, account, password) {
        await page.goto('/login.html');
        await page.fill('#accountInput', account);
        await page.fill('#passwordInput', password);
        await page.click('#loginButton');
        await expect(page).toHaveURL(/.*index\.html/);
    }

    test.beforeEach(async ({ page }) => {
        // 创建测试用户并登录
        const phone = '138' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        await page.goto('/register.html');
        await page.click('[data-register-type="phone"]');
        await page.fill('#phoneInput', phone);
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '123456');
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');
        await page.click('#registerButton');

        await login(page, phone, '123456');
    });

    test('创建笔记', async ({ page }) => {
        // 点击新建笔记按钮
        await page.click('#createNoteButton');

        // 填写笔记内容
        await page.fill('#noteTitle', '测试笔记标题');
        await page.fill('#noteContent', '这是测试笔记的内容');

        // 保存笔记
        await page.click('#saveNoteButton');

        // 验证笔记出现在列表中
        await expect(page.locator('.note-item').filter({
            hasText: '测试笔记标题'
        })).toBeVisible();
    });

    test('编辑笔记', async ({ page }) => {
        // 先创建一个笔记
        await page.click('#createNoteButton');
        await page.fill('#noteTitle', '原始标题');
        await page.fill('#noteContent', '原始内容');
        await page.click('#saveNoteButton');
        await expect(page.locator('.note-item').filter({
            hasText: '原始标题'
        })).toBeVisible();

        // 点击编辑按钮
        await page.locator('.note-item').filter({
            hasText: '原始标题'
        }).click();
        await page.click('#editNoteButton');

        // 修改笔记内容
        await page.fill('#noteTitle', '修改后的标题');
        await page.fill('#noteContent', '修改后的内容');
        await page.click('#saveNoteButton');

        // 验证修改成功
        await expect(page.locator('.note-item').filter({
            hasText: '修改后的标题'
        })).toBeVisible();
    });

    test('删除笔记', async ({ page }) => {
        // 创建笔记
        await page.click('#createNoteButton');
        await page.fill('#noteTitle', '待删除笔记');
        await page.fill('#noteContent', '即将被删除');
        await page.click('#saveNoteButton');

        // 点击删除按钮
        await page.locator('.note-item').filter({
            hasText: '待删除笔记'
        }).locator('.delete-btn').click();

        // 确认删除
        page.on('dialog', dialog => dialog.accept());

        // 验证笔记已删除
        await expect(page.locator('.note-item').filter({
            hasText: '待删除笔记'
        })).not.toBeVisible();
    });

    // 待后端分页 API 实现后启用
    test.skip('笔记列表分页', async ({ page }) => {
        // TODO: 等待后端实现 GET /api/notes?page=1&page_size=10
        // 创建20个笔记
        for (let i = 0; i < 20; i++) {
            await page.click('#createNoteButton');
            await page.fill('#noteTitle', `笔记 ${i}`);
            await page.fill('#noteContent', `内容 ${i}`);
            await page.click('#saveNoteButton');
            await page.goBack();
        }

        // 验证第一页显示
        await expect(page.locator('.note-item')).toHaveCount(10);

        // 点击下一页
        await page.click('.pagination-next');

        // 验证第二页显示
        await expect(page.locator('.note-item')).toHaveCount(10);
    });

    // 待后端搜索 API 实现后启用
    test.skip('笔记搜索', async ({ page }) => {
        // TODO: 等待后端实现 GET /api/notes?keyword=工作
        // 创建多个笔记
        const keywords = ['工作', '学习', '生活'];
        for (const keyword of keywords) {
            await page.click('#createNoteButton');
            await page.fill('#noteTitle', `${keyword}笔记`);
            await page.fill('#noteContent', `${keyword}相关内容`);
            await page.click('#saveNoteButton');
            await page.goBack();
        }

        // 搜索
        await page.fill('#searchInput', '工作');
        await page.press('#searchInput', 'Enter');

        // 验证只显示搜索结果
        await expect(page.locator('.note-item')).toHaveCount(1);
        await expect(page.locator('.note-item')).toContainText('工作');
    });

    test('笔记标题不能为空', async ({ page }) => {
        await page.click('#createNoteButton');
        await page.fill('#noteContent', '只有内容没有标题');
        await page.click('#saveNoteButton');

        // 验证显示错误
        await expect(page.locator('#noteTitle-error')).toContainText(
            '标题不能为空'
        );
    });
});
```

**完整用户流程E2E测试 (`e2e/full-flow.spec.js`)：**
```javascript
const { test, expect } = require('@playwright/test');

test.describe('完整用户流程', () => {

    test('从注册到完成所有操作的完整流程', async ({ page }) => {
        const phone = '138' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        const password = '123456';

        // 1. 手机号注册
        await page.goto('/register.html');
        await page.click('[data-register-type="phone"]');
        await page.fill('#phoneInput', phone);
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '123456');
        await page.fill('#password', password);
        await page.fill('#confirmPassword', password);
        await page.fill('#nickname', '全流程测试用户');
        await page.click('#registerButton');
        await expect(page).toHaveURL(/.*login\.html/);

        // 2. 登录
        await page.fill('#accountInput', phone);
        await page.fill('#passwordInput', password);
        await page.click('#loginButton');
        await expect(page).toHaveURL(/.*index\.html/);

        // 3. 创建目录
        await page.click('#createFolderButton');
        await page.fill('#folderName', '工作笔记');
        await page.click('#confirmFolderButton');
        await expect(page.locator('.folder-item').filter({
            hasText: '工作笔记'
        })).toBeVisible();

        // 4. 在目录下创建笔记
        await page.locator('.folder-item').filter({
            hasText: '工作笔记'
        }).click();
        await page.click('#createNoteButton');
        await page.fill('#noteTitle', '项目计划');
        await page.fill('#noteContent', '这是项目计划的内容');
        await page.fill('#noteFolderSelect', '工作笔记');
        await page.click('#saveNoteButton');

        // 5. 查看笔记详情
        await page.locator('.note-item').filter({
            hasText: '项目计划'
        }).click();
        await expect(page.locator('.note-detail-title')).toContainText(
            '项目计划'
        );
        await expect(page.locator('.note-detail-content')).toContainText(
            '这是项目计划的内容'
        );

        // 6. 编辑笔记
        await page.click('#editNoteButton');
        await page.fill('#noteTitle', '更新的项目计划');
        await page.fill('#noteContent', '更新后的内容');
        await page.click('#saveNoteButton');
        await expect(page.locator('.note-item').filter({
            hasText: '更新的项目计划'
        })).toBeVisible();

        // 7. 删除笔记
        page.on('dialog', dialog => dialog.accept());
        await page.locator('.note-item').filter({
            hasText: '更新的项目计划'
        }).locator('.delete-btn').click();
        await expect(page.locator('.note-item').filter({
            hasText: '更新的项目计划'
        })).not.toBeVisible();

        // 8. 删除目录
        page.on('dialog', dialog => dialog.accept());
        await page.locator('.folder-item').filter({
            hasText: '工作笔记'
        }).locator('.delete-folder-btn').click();
        await expect(page.locator('.folder-item').filter({
            hasText: '工作笔记'
        })).not.toBeVisible();

        // 9. 登出
        await page.click('#logoutButton');
        await expect(page).toHaveURL(/.*login\.html/);
    });
});
```

**目录流程E2E测试 (`e2e/folders.spec.js`)：**
```javascript
const { test, expect } = require('@playwright/test');

test.describe('目录管理 E2E 测试', () => {

    // 辅助函数：注册并登录
    async function registerAndLogin(page) {
        const phone = '138' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        await page.goto('/register.html');
        await page.click('[data-register-type="phone"]');
        await page.fill('#phoneInput', phone);
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '123456');
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');
        await page.click('#registerButton');

        await page.goto('/login.html');
        await page.fill('#accountInput', phone);
        await page.fill('#passwordInput', '123456');
        await page.click('#loginButton');
        await expect(page).toHaveURL(/.*index\.html/);
    }

    test.beforeEach(async ({ page }) => {
        await registerAndLogin(page);
    });

    test('创建目录', async ({ page }) => {
        await page.click('#createFolderButton');
        await page.fill('#folderName', '工作笔记');
        await page.click('#confirmFolderButton');

        await expect(page.locator('.folder-item').filter({
            hasText: '工作笔记'
        })).toBeVisible();
    });

    test('获取目录列表', async ({ page }) => {
        // 创建多个目录
        const folders = ['工作', '学习', '生活'];
        for (const name of folders) {
            await page.click('#createFolderButton');
            await page.fill('#folderName', name);
            await page.click('#confirmFolderButton');
            await expect(page.locator('.folder-item').filter({
                hasText: name
            })).toBeVisible();
        }

        // 验证目录数量
        await expect(page.locator('.folder-item')).toHaveCount(3);
    });

    test('删除目录', async ({ page }) => {
        // 创建目录
        await page.click('#createFolderButton');
        await page.fill('#folderName', '待删除目录');
        await page.click('#confirmFolderButton');

        // 删除目录
        page.on('dialog', dialog => dialog.accept());
        await page.locator('.folder-item').filter({
            hasText: '待删除目录'
        }).locator('.delete-folder-btn').click();

        // 验证已删除
        await expect(page.locator('.folder-item').filter({
            hasText: '待删除目录'
        })).not.toBeVisible();
    });

    test('点击目录显示其下笔记', async ({ page }) => {
        // 创建目录
        await page.click('#createFolderButton');
        await page.fill('#folderName', '测试目录');
        await page.click('#confirmFolderButton');

        // 在目录下创建笔记
        await page.locator('.folder-item').filter({
            hasText: '测试目录'
        }).click();
        await page.click('#createNoteButton');
        await page.fill('#noteTitle', '目录下的笔记');
        await page.fill('#noteContent', '内容');
        await page.fill('#noteFolderSelect', '测试目录');
        await page.click('#saveNoteButton');
        await page.goBack();

        // 点击目录，验证显示笔记
        await page.locator('.folder-item').filter({
            hasText: '测试目录'
        }).click();
        await expect(page.locator('.note-item').filter({
            hasText: '目录下的笔记'
        })).toBeVisible();
    });
});
```

**个人信息E2E测试 (`e2e/profile.spec.js`)：**
```javascript
const { test, expect } = require('@playwright/test');

test.describe('个人信息 E2E 测试', () => {

    // 辅助函数：注册并登录
    async function registerAndLogin(page) {
        const phone = '138' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        await page.goto('/register.html');
        await page.click('[data-register-type="phone"]');
        await page.fill('#phoneInput', phone);
        await page.click('#sendCodeButton');
        await page.fill('#codeInput', '123456');
        await page.fill('#password', '123456');
        await page.fill('#confirmPassword', '123456');
        await page.fill('#nickname', '初始昵称');
        await page.click('#registerButton');

        await page.goto('/login.html');
        await page.fill('#accountInput', phone);
        await page.fill('#passwordInput', '123456');
        await page.click('#loginButton');
        await expect(page).toHaveURL(/.*index\.html/);
    }

    test.beforeEach(async ({ page }) => {
        await registerAndLogin(page);
    });

    test('查看个人信息', async ({ page }) => {
        await page.click('#profileLink');
        await expect(page).toHaveURL(/.*profile\.html/);

        // 验证显示个人信息
        await expect(page.locator('#profileNickname')).toContainText('初始昵称');
        await expect(page.locator('#profilePhone')).toContainText('138****');  // 脱敏显示
    });

    test('修改昵称', async ({ page }) => {
        await page.click('#profileLink');

        // 点击编辑昵称
        await page.click('#editNicknameBtn');

        // 输入新昵称
        await page.fill('#nicknameInput', '新昵称');
        await page.click('#saveNicknameBtn');

        // 验证修改成功
        await expect(page.locator('.success-message')).toBeVisible();
        await expect(page.locator('#profileNickname')).toContainText('新昵称');
    });

    test('上传头像', async ({ page }) => {
        await page.click('#profileLink');

        // 上传头像
        const fileInput = await page.locator('#avatarUpload');
        await fileInput.setInputFiles('test-assets/test-avatar.jpg');

        // 验证头像更新
        await expect(page.locator('.success-message')).toBeVisible();
        await expect(page.locator('#profileAvatar')).toBeVisible();
    });

    test('修改生日', async ({ page }) => {
        await page.click('#profileLink');

        // 点击编辑生日
        await page.click('#editBirthdayBtn');

        // 使用日期选择器
        await page.fill('#birthdayInput', '1995-06-15');
        await page.click('#saveBirthdayBtn');

        // 验证修改成功
        await expect(page.locator('.success-message')).toBeVisible();
        await expect(page.locator('#profileBirthday')).toContainText('1995-06-15');
    });

    test('修改手机号（需验证码）', async ({ page }) => {
        await page.click('#profileLink');

        // 点击修改手机号
        await page.click('#editPhoneBtn');

        // 输入新手机号
        const newPhone = '139' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
        await page.fill('#newPhoneInput', newPhone);

        // 获取验证码
        await page.click('#sendPhoneCodeBtn');
        await expect(page.locator('.code-sent-message')).toBeVisible();

        // 输入验证码
        await page.fill('#phoneCodeInput', '123456');
        await page.click('#savePhoneBtn');

        // 验证修改成功（显示脱敏手机号）
        await expect(page.locator('.success-message')).toBeVisible();
        await expect(page.locator('#profilePhone')).toContainText('139****');
    });

    test('修改邮箱（需验证码）', async ({ page }) => {
        await page.click('#profileLink');

        await page.click('#editEmailBtn');

        const newEmail = 'new_' + Date.now() + '@example.com';
        await page.fill('#newEmailInput', newEmail);

        await page.click('#sendEmailCodeBtn');
        await page.fill('#emailCodeInput', '654321');
        await page.click('#saveEmailBtn');

        await expect(page.locator('.success-message')).toBeVisible();
        await expect(page.locator('#profileEmail')).toContainText(newEmail);
    });

    test('修改密码', async ({ page }) => {
        await page.goto('/change-password.html');

        // 输入旧密码
        await page.fill('#oldPassword', '123456');

        // 输入新密码
        await page.fill('#newPassword', '654321');
        await page.fill('#confirmNewPassword', '654321');

        // 提交
        await page.click('#changePasswordBtn');

        // 验证修改成功
        await expect(page.locator('.success-message')).toContainText('密码修改成功');
    });

    test('修改密码 - 旧密码错误', async ({ page }) => {
        await page.goto('/change-password.html');

        await page.fill('#oldPassword', '111111');
        await page.fill('#newPassword', '654321');
        await page.fill('#confirmNewPassword', '654321');
        await page.click('#changePasswordBtn');

        await expect(page.locator('.error-message')).toContainText('旧密码错误');
    });

    test('修改密码 - 新密码格式错误', async ({ page }) => {
        await page.goto('/change-password.html');

        await page.fill('#oldPassword', '123456');
        await page.fill('#newPassword', '12345');  // 只有5位
        await page.fill('#confirmNewPassword', '12345');
        await page.click('#changePasswordBtn');

        await expect(page.locator('.error-message')).toContainText('密码必须为6位数字');
    });

    test('修改密码 - 两次输入不一致', async ({ page }) => {
        await page.goto('/change-password.html');

        await page.fill('#oldPassword', '123456');
        await page.fill('#newPassword', '654321');
        await page.fill('#confirmNewPassword', '111111');
        await page.click('#changePasswordBtn');

        await expect(page.locator('.error-message')).toContainText('两次输入的密码不一致');
    });

    test('修改密码后重新登录', async ({ page }) => {
        // 修改密码
        await page.goto('/change-password.html');
        await page.fill('#oldPassword', '123456');
        await page.fill('#newPassword', '654321');
        await page.fill('#confirmNewPassword', '654321');
        await page.click('#changePasswordBtn');

        // 登出
        await page.goto('/index.html');
        await page.click('#logoutButton');
        await expect(page).toHaveURL(/.*login\.html/);

        // 使用新密码登录
        // 注意：需要使用注册时的手机号
        const phone = await page.evaluate(() => {
            // 从localStorage获取用户信息
            const user = JSON.parse(localStorage.getItem('userInfo') || '{}');
            return user.phone;
        });

        await page.fill('#accountInput', phone);
        await page.fill('#passwordInput', '654321');
        await page.click('#loginButton');
        await expect(page).toHaveURL(/.*index\.html/);

        // 使用旧密码登录应该失败
        await page.click('#logoutButton');
        await page.fill('#accountInput', phone);
        await page.fill('#passwordInput', '123456');
        await page.click('#loginButton');
        await expect(page.locator('.error-message')).toContainText('账号或密码错误');
    });
});
```

**运行E2E测试命令：**
```bash
# 运行所有E2E测试
npx playwright test

# 运行特定浏览器的测试
npx playwright test --project=chromium

# 运行特定文件
npx playwright test e2e/auth.spec.js

# 带UI模式运行（可视化调试）
npx playwright test --ui

# 生成HTML报告
npx playwright show-report

# 以特定并发数运行
npx playwright test --workers=4

# 调试模式
PWDEBUG=1 npx playwright test
```

#### 2.3 UI 组件测试

**测试工具：** Jest + jsdom

**UI组件测试示例 (`__tests__/components.test.js`)：**
```javascript
/**
 * @jest-environment jsdom
 */

describe('UI 组件测试', () => {

    describe('笔记卡片组件', () => {
        beforeEach(() => {
            document.body.innerHTML = `
                <div class="note-card" data-id="1">
                    <h3 class="note-title">测试笔记</h3>
                    <p class="note-preview">这是预览内容...</p>
                    <div class="note-meta">
                        <span class="note-date">2024-01-01</span>
                    </div>
                    <button class="edit-btn">编辑</button>
                    <button class="delete-btn">删除</button>
                </div>
            `;
        });

        test('正确渲染笔记卡片', () => {
            const card = document.querySelector('.note-card');
            expect(card).toBeTruthy();

            const title = card.querySelector('.note-title');
            expect(title.textContent).toBe('测试笔记');

            const preview = card.querySelector('.note-preview');
            expect(preview.textContent).toBe('这是预览内容...');
        });

        test('点击编辑按钮触发编辑事件', () => {
            const editBtn = document.querySelector('.edit-btn');
            let editClicked = false;

            editBtn.addEventListener('click', () => {
                editClicked = true;
            });

            editBtn.click();
            expect(editClicked).toBe(true);
        });

        test('点击删除按钮触发删除事件', () => {
            const deleteBtn = document.querySelector('.delete-btn');
            let deleteClicked = false;

            deleteBtn.addEventListener('click', () => {
                deleteClicked = true;
            });

            deleteBtn.click();
            expect(deleteClicked).toBe(true);
        });

        test('长标题自动截断显示', () => {
            const title = document.querySelector('.note-title');
            title.textContent = '这是一个非常非常非常长的笔记标题'.repeat(10);

            // 检查CSS样式是否应用
            const style = window.getComputedStyle(title);
            expect(style.textOverflow).toBe('ellipsis');
        });
    });

    describe('目录列表组件', () => {
        beforeEach(() => {
            document.body.innerHTML = `
                <ul class="folder-list">
                    <li class="folder-item" data-id="1">
                        <span class="folder-icon">📁</span>
                        <span class="folder-name">工作</span>
                        <span class="note-count">5</span>
                        <button class="delete-folder-btn">删除</button>
                    </li>
                    <li class="folder-item" data-id="2">
                        <span class="folder-icon">📁</span>
                        <span class="folder-name">学习</span>
                        <span class="note-count">3</span>
                        <button class="delete-folder-btn">删除</button>
                    </li>
                </ul>
            `;
        });

        test('正确渲染目录列表', () => {
            const items = document.querySelectorAll('.folder-item');
            expect(items.length).toBe(2);
        });

        test('显示目录下的笔记数量', () => {
            const firstCount = document.querySelector(
                '.folder-item:first-child .note-count'
            );
            expect(firstCount.textContent).toBe('5');
        });

        test('点击目录选中状态', () => {
            const firstItem = document.querySelector('.folder-item');
            firstItem.click();

            expect(firstItem.classList.contains('active')).toBe(true);
        });
    });

    describe('表单验证组件', () => {
        test('密码验证（6位数字）', () => {
            // 有效 - 6位数字
            expect(validatePassword('123456')).toBe(true);
            expect(validatePassword('000000')).toBe(true);
            expect(validatePassword('999999')).toBe(true);
            // 无效 - 长度不对
            expect(validatePassword('12345')).toBe(false);
            expect(validatePassword('1234567')).toBe(false);
            expect(validatePassword('')).toBe(false);
            // 无效 - 包含非数字
            expect(validatePassword('12345a')).toBe(false);
            expect(validatePassword('abcdef')).toBe(false);
            expect(validatePassword('12345!')).toBe(false);
        });

        test('手机号格式验证', () => {
            // 有效 - 中国大陆手机号
            expect(validatePhone('13800138000')).toBe(true);
            expect(validatePhone('15912345678')).toBe(true);
            // 无效
            expect(validatePhone('12345678901')).toBe(false);  // 不以1[3-9]开头
            expect(validatePhone('1380013800')).toBe(false);   // 长度不对
            expect(validatePhone('abc')).toBe(false);
        });

        test('邮箱格式验证', () => {
            expect(validateEmail('test@example.com')).toBe(true);
            expect(validateEmail('user.name@domain.org')).toBe(true);
            expect(validateEmail('not-an-email')).toBe(false);
            expect(validateEmail('missing@')).toBe(false);
            expect(validateEmail('@nodomain.com')).toBe(false);
        });

        test('用户名长度验证', () => {
            expect(validateUsername('ab')).toBe(false);  // 太短
            expect(validateUsername('testuser')).toBe(true);
            expect(validateUsername('a'.repeat(51))).toBe(false);  // 太长
        });
    });
});
```

#### 2.4 Web 性能测试

**工具选型：**
- Lighthouse (Google 官方性能分析工具)
- Web Vitals (核心性能指标)
- Lighthouse CI (持续集成)

**安装依赖：**
```bash
npm install --save-dev lighthouse lighthouse-ci webpack-bundle-analyzer
```

**项目结构：**
```
web/
├── perf/
│   ├── lighthouse.config.js       # Lighthouse配置
│   ├── lighthouse-ci.config.js    # Lighthouse CI配置
│   ├── performance.test.js        # 性能测试脚本
│   ├── bundle-analysis.js         # 包大小分析
│   └── metrics/
│       └── web-vitals.js          # Web Vitals监控
└── package.json
```

**Lighthouse 配置 (`perf/lighthouse.config.js`)：**
```javascript
module.exports = {
    settings: {
        onlyCategories: [
            'performance',
            'accessibility',
            'best-practices',
            'seo'
        ],
        throttleMethod: 'simulate',
        emulatedFormFactor: 'desktop',
    },
    opts: {
        output: ['html', 'json'],
        outputPath: './perf/reports',
    },
};
```

**Lighthouse CI 配置 (`perf/lighthouse-ci.config.js`)：**
```javascript
module.exports = {
    ci: {
        collect: {
            url: [
                'http://localhost:5500/index.html',
                'http://localhost:5500/login.html',
                'http://localhost:5500/register.html'
            ],
            numberOfRuns: 3,
            startServerCommand: 'npm run start',
        },
        assert: {
            assertions: {
                'categories:performance': ['error', { minScore: 0.9 }],
                'categories:accessibility': ['error', { minScore: 0.95 }],
                'categories:best-practices': ['error', { minScore: 0.9 }],
                'categories:seo': ['error', { minScore: 0.9 }],

                // 关键性能指标
                'first-contentful-paint': ['error', { maxNumericValue: 2000 }],
                'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
                'interactive': ['error', { maxNumericValue: 3500 }],
                'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
                'total-blocking-time': ['error', { maxNumericValue: 300 }],
                'speed-index': ['error', { maxNumericValue: 3000 }],
            },
        },
        upload: {
            target: 'temporary-public-storage',
        },
    },
};
```

**性能测试脚本 (`perf/performance.test.js`)：**
```javascript
/**
 * Web端性能测试
 */
const lighthouse = require('lighthouse');
const chromeLauncher = require('chrome-launcher');

const PERFORMANCE_BUDGET = {
    // 时间指标（毫秒）
    firstContentfulPaint: 2000,      // 首次内容绘制
    largestContentfulPaint: 2500,    // 最大内容绘制
    timeToInteractive: 3500,         // 可交互时间
    speedIndex: 3000,                // 速度指数
    totalBlockingTime: 300,          // 总阻塞时间
    cumulativeLayoutShift: 0.1,      // 累积布局偏移

    // 资源大小（字节）
    totalSize: 500 * 1024,           // 总大小 ≤ 500KB
    jsSize: 200 * 1024,              // JS大小 ≤ 200KB
    cssSize: 100 * 1024,             // CSS大小 ≤ 100KB
    imageSize: 200 * 1024,           // 图片大小 ≤ 200KB

    // 请求数
    totalRequests: 30,               // 总请求数 ≤ 30
};

async function runPerformanceTest(url) {
    const chrome = await chromeLauncher.launch({
        chromeFlags: ['--headless', '--disable-gpu']
    });

    const options = {
        logLevel: 'info',
        output: 'json',
        onlyCategories: ['performance'],
        port: chrome.port,
    };

    try {
        const runnerResult = await lighthouse(url, options);
        const report = JSON.parse(runnerResult.report);

        console.log('\n=== 性能测试报告 ===');
        console.log(`URL: ${url}`);
        console.log(`性能得分: ${report.categories.performance.score * 100}/100`);
        console.log('\n--- 关键指标 ---');
        console.log(`首次内容绘制 (FCP): ${report.audits['first-contentful-paint'].numericValue}ms`);
        console.log(`最大内容绘制 (LCP): ${report.audits['largest-contentful-paint'].numericValue}ms`);
        console.log(`可交互时间 (TTI): ${report.audits['interactive'].numericValue}ms`);
        console.log(`速度指数 (SI): ${report.audits['speed-index'].numericValue}`);
        console.log(`总阻塞时间 (TBT): ${report.audits['total-blocking-time'].numericValue}ms`);
        console.log(`累积布局偏移 (CLS): ${report.audits['cumulative-layout-shift'].numericValue}`);

        // 验证性能预算
        const violations = checkPerformanceBudget(report);
        if (violations.length > 0) {
            console.log('\n⚠️  性能预算违规：');
            violations.forEach(v => console.log(`  - ${v}`));
        }

        return { report, violations };
    } finally {
        await chrome.kill();
    }
}

function checkPerformanceBudget(report) {
    const violations = [];

    // 检查时间指标
    if (report.audits['first-contentful-paint'].numericValue >
        PERFORMANCE_BUDGET.firstContentfulPaint) {
        violations.push(
            `FCP 超过预算: ${report.audits['first-contentful-paint'].numericValue}ms > ${PERFORMANCE_BUDGET.firstContentfulPaint}ms`
        );
    }

    if (report.audits['largest-contentful-paint'].numericValue >
        PERFORMANCE_BUDGET.largestContentfulPaint) {
        violations.push(
            `LCP 超过预算: ${report.audits['largest-contentful-paint'].numericValue}ms > ${PERFORMANCE_BUDGET.largestContentfulPaint}ms`
        );
    }

    if (report.audits['interactive'].numericValue >
        PERFORMANCE_BUDGET.timeToInteractive) {
        violations.push(
            `TTI 超过预算: ${report.audits['interactive'].numericValue}ms > ${PERFORMANCE_BUDGET.timeToInteractive}ms`
        );
    }

    // 检查资源大小
    const totalByteWeight = report.audits['total-byte-weight'].numericValue;
    if (totalByteWeight > PERFORMANCE_BUDGET.totalSize) {
        violations.push(
            `总资源大小超过预算: ${(totalByteWeight / 1024).toFixed(2)}KB > ${PERFORMANCE_BUDGET.totalSize / 1024}KB`
        );
    }

    return violations;
}

// 运行所有页面的性能测试
async function runAllTests() {
    const pages = [
        'http://localhost:5500/index.html',
        'http://localhost:5500/login.html',
        'http://localhost:5500/register.html'
    ];

    const results = {};
    for (const page of pages) {
        results[page] = await runPerformanceTest(page);
    }

    return results;
}

// 如果是直接运行脚本
if (require.main === module) {
    runAllTests().catch(console.error);
}

module.exports = { runPerformanceTest, runAllTests, PERFORMANCE_BUDGET };
```

**Web Vitals 监控 (`perf/metrics/web-vitals.js`)：**
```javascript
/**
 * Web Vitals 性能指标监控
 */
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

class PerformanceMonitor {
    constructor() {
        this.metrics = {};
        this.init();
    }

    init() {
        // Cumulative Layout Shift (CLS) - 累积布局偏移
        getCLS(this.handleMetric.bind(this, 'CLS'));

        // First Input Delay (FID) - 首次输入延迟
        getFID(this.handleMetric.bind(this, 'FID'));

        // First Contentful Paint (FCP) - 首次内容绘制
        getFCP(this.handleMetric.bind(this, 'FCP'));

        // Largest Contentful Paint (LCP) - 最大内容绘制
        getLCP(this.handleMetric.bind(this, 'LCP'));

        // Time to First Byte (TTFB) - 首字节时间
        getTTFB(this.handleMetric.bind(this, 'TTFB'));
    }

    handleMetric(name, metric) {
        this.metrics[name] = metric.value;

        // 上报到后端或日志系统
        this.reportMetric(name, metric);

        // 控制台输出（开发模式）
        if (process.env.NODE_ENV === 'development') {
            console.log(`[Performance] ${name}: ${metric.value} ${metric.rating}`);
        }
    }

    reportMetric(name, metric) {
        // 使用 navigator.sendBeacon 可靠地发送数据
        const data = {
            metric: name,
            value: metric.value,
            rating: metric.rating,
            delta: metric.delta,
            id: metric.id,
            navigationType: metric.navigationType,
            url: window.location.href,
            timestamp: Date.now(),
        };

        // 发送到后端分析接口
        if (navigator.sendBeacon) {
            navigator.sendBeacon('/api/analytics/performance',
                JSON.stringify(data));
        }
    }

    getMetrics() {
        return { ...this.metrics };
    }

    // 性能指标评估标准
    static getThresholds() {
        return {
            CLS: { good: 0.1, needsImprovement: 0.25 },
            FID: { good: 100, needsImprovement: 300 },
            FCP: { good: 1800, needsImprovement: 3000 },
            LCP: { good: 2500, needsImprovement: 4000 },
            TTFB: { good: 800, needsImprovement: 1800 },
        };
    }
}

// 导出单例
export const perfMonitor = new PerformanceMonitor();
export default PerformanceMonitor;
```

**包大小分析 (`perf/bundle-analysis.js`)：**
```javascript
/**
 * 分析打包文件大小
 */
const fs = require('fs');
const path = require('path');

const BUNDLE_BUDGET = {
    'js/app.js': 50 * 1024,       // 50KB
    'js/auth.js': 20 * 1024,      // 20KB
    'js/notes.js': 30 * 1024,     // 30KB
    'js/folders.js': 20 * 1024,   // 20KB
    'js/api.js': 15 * 1024,       // 15KB
    'css/style.css': 30 * 1024,   // 30KB
};

function analyzeBundle() {
    console.log('\n=== 包大小分析报告 ===\n');

    let hasViolations = false;
    let totalSize = 0;

    for (const [file, budget] of Object.entries(BUNDLE_BUDGET)) {
        const filePath = path.join(__dirname, '..', file);

        if (!fs.existsSync(filePath)) {
            console.log(`⚠️  文件不存在: ${file}`);
            continue;
        }

        const stats = fs.statSync(filePath);
        const size = stats.size;
        totalSize += size;

        const status = size <= budget ? '✅' : '❌';
        const percentage = ((size / budget) * 100).toFixed(1);

        console.log(
            `${status} ${file}: ${(size / 1024).toFixed(2)}KB / ${(budget / 1024).toFixed(2)}KB (${percentage}%)`
        );

        if (size > budget) {
            hasViolations = true;
        }
    }

    console.log(`\n总大小: ${(totalSize / 1024).toFixed(2)}KB`);

    if (hasViolations) {
        console.log('\n⚠️  存在包大小违规，请优化！');
        process.exit(1);
    } else {
        console.log('\n✅ 所有文件大小符合预算');
    }
}

if (require.main === module) {
    analyzeBundle();
}

module.exports = { analyzeBundle, BUNDLE_BUDGET };
```

#### 2.5 Web 压力测试

**工具选型：**
- k6 (现代化负载测试工具)
- Artillery (Node.js负载测试)
- Locust (Python负载测试)

**k6 安装：**
```bash
# macOS
brew install k6

# 其他平台参考：https://k6.io/docs/getting-started/installation/
```

**k6 压测脚本 (`perf/load/auth-load.js`)：**
```javascript
/**
 * 登录接口压力测试
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自定义指标
const loginFailRate = new Rate('login_failed');
const loginDuration = new Trend('login_duration');

// 压测配置
export const options = {
    stages: [
        { duration: '30s', target: 20 },   // 逐步增加到20用户
        { duration: '1m', target: 50 },    // 增加到50用户
        { duration: '30s', target: 100 },  // 增加到100用户
        { duration: '1m', target: 100 },   // 保持100用户1分钟
        { duration: '30s', target: 50 },   // 降低到50用户
        { duration: '30s', target: 0 },    // 逐步减少到0
    ],
    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1000'],  // 95%请求<500ms
        http_req_failed: ['rate<0.01'],                   // 错误率<1%
        login_failed: ['rate<0.01'],
        login_duration: ['avg<300', 'p(95)<800'],
    },
};

const BASE_URL = 'http://localhost:8080';

export default function () {
    // 模拟登录
    const payload = JSON.stringify({
        username: 'loadtest_user',
        password: '123456',
    });

    const params = {
        headers: { 'Content-Type': 'application/json' },
    };

    const res = http.post(`${BASE_URL}/api/auth/login`, payload, params);
    loginDuration.add(res.timings.duration);

    const success = check(res, {
        '登录成功': (r) => r.status === 200,
        '返回Token': (r) => {
            const body = r.json();
            return body.code === 200 && body.data.token;
        },
        '响应时间合理': (r) => r.timings.duration < 1000,
    });

    loginFailRate.add(!success);

    // 模拟用户思考时间
    sleep(Math.random() * 2 + 1);
}

export function handleSummary(data) {
    return {
        'stdout': textSummary(data, { indent: ' ', enableColors: true }),
        './perf/reports/auth-load-result.json': JSON.stringify(data, null, 2),
    };
}
```

**k6 综合压测脚本 (`perf/load/full-load.js`)：**
```javascript
/**
 * 完整应用压力测试
 */
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Counter } from 'k6/metrics';

const errorRate = new Rate('errors');
const noteCreateCount = new Counter('notes_created');

export const options = {
    scenarios: {
        // 场景1：主要读操作
        read_operations: {
            executor: 'constant-vus',
            vus: 50,
            duration: '2m',
            exec: 'readOperations',
        },
        // 场景2：混合操作
        mixed_operations: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 30 },
                { duration: '1m', target: 80 },
                { duration: '30s', target: 0 },
            ],
            exec: 'mixedOperations',
            startTime: '30s',
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<500'],
        errors: ['rate<0.05'],
    },
};

const BASE_URL = 'http://localhost:8080';
let authToken = null;

// 登录获取token
function login() {
    const res = http.post(`${BASE_URL}/api/auth/login`,
        JSON.stringify({
            username: 'loadtest_user',
            password: '123456',
        }),
        { headers: { 'Content-Type': 'application/json' } }
    );

    if (res.status === 200) {
        const body = res.json();
        authToken = body.data.token;
    }

    return authToken;
}

// 读操作场景
export function readOperations() {
    if (!authToken) login();

    group('读取操作', function () {
        // 获取笔记列表
        const notesRes = http.get(`${BASE_URL}/api/notes`, {
            headers: { 'Authorization': `Bearer ${authToken}` },
        });

        check(notesRes, {
            '获取笔记列表成功': (r) => r.status === 200,
        }) || errorRate.add(1);

        sleep(1);

        // 获取目录列表
        const foldersRes = http.get(`${BASE_URL}/api/folders`, {
            headers: { 'Authorization': `Bearer ${authToken}` },
        });

        check(foldersRes, {
            '获取目录列表成功': (r) => r.status === 200,
        }) || errorRate.add(1);

        sleep(1);
    });
}

// 混合操作场景
export function mixedOperations() {
    if (!authToken) login();

    const rand = Math.random();

    if (rand < 0.5) {
        // 50% 概率：读取笔记
        group('读取笔记', function () {
            const res = http.get(`${BASE_URL}/api/notes`, {
                headers: { 'Authorization': `Bearer ${authToken}` },
            });
            check(res, { '读取成功': (r) => r.status === 200 });
        });
    } else if (rand < 0.8) {
        // 30% 概率：创建笔记
        group('创建笔记', function () {
            const payload = JSON.stringify({
                title: `压测笔记_${Date.now()}`,
                content: '压测内容'.repeat(100),
                folder_id: 1,
            });

            const res = http.post(`${BASE_URL}/api/notes`, payload, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${authToken}`,
                },
            });

            if (check(res, { '创建成功': (r) => r.status === 200 })) {
                noteCreateCount.add(1);
            } else {
                errorRate.add(1);
            }
        });
    } else if (rand < 0.95) {
        // 15% 概率：更新笔记
        group('更新笔记', function () {
            const payload = JSON.stringify({
                title: `更新笔记_${Date.now()}`,
                content: '更新内容',
            });

            const res = http.put(`${BASE_URL}/api/notes/1`, payload, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${authToken}`,
                },
            });

            check(res, { '更新成功': (r) => r.status === 200 }) || errorRate.add(1);
        });
    } else {
        // 5% 概率：删除笔记
        group('删除笔记', function () {
            const res = http.del(`${BASE_URL}/api/notes/1`, null, {
                headers: { 'Authorization': `Bearer ${authToken}` },
            });
            check(res, { '删除成功': (r) => r.status === 200 }) || errorRate.add(1);
        });
    }

    sleep(Math.random() * 2 + 0.5);
}
```

**运行k6压测命令：**
```bash
# 运行登录接口压测
k6 run perf/load/auth-load.js

# 运行综合压测
k6 run perf/load/full-load.js

# 生成HTML报告
k6 run --out json=perf/reports/result.json perf/load/full-load.js

# 云端压测（需要注册k6 cloud）
k6 cloud perf/load/full-load.js

# 指定并发数和持续时间
k6 run --vus 100 --duration 30s perf/load/auth-load.js
```

**运行Web测试和性能测试命令汇总：**
```bash
cd web

# 1. 单元测试
npm test

# 2. 单元测试 + 覆盖率
npm test -- --coverage

# 3. E2E测试
npx playwright test

# 4. 性能测试（Lighthouse）
node perf/performance.test.js

# 5. Lighthouse CI
npm install -g @lhci/cli@latest
lhci autorun --config=perf/lighthouse-ci.config.js

# 6. 压力测试
k6 run perf/load/auth-load.js
k6 run perf/load/full-load.js

# 7. 包大小分析
node perf/bundle-analysis.js

# 8. 运行所有测试（一键脚本）
npm run test:all
```

**package.json 脚本：**
```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:perf": "node perf/performance.test.js",
    "test:perf:lighthouse": "lhci autorun",
    "test:load:auth": "k6 run perf/load/auth-load.js",
    "test:load:full": "k6 run perf/load/full-load.js",
    "test:bundle": "node perf/bundle-analysis.js",
    "test:all": "npm run test && npm run test:e2e && npm run test:perf && npm run test:bundle"
  }
}
```

**Web端性能指标目标：**
| 指标 | 目标值 | 警告值 | 严重值 |
|------|--------|--------|--------|
| First Contentful Paint | < 1.5s | < 2.5s | > 4s |
| Largest Contentful Paint | < 2s | < 3s | > 4s |
| Time to Interactive | < 3s | < 4s | > 6s |
| Cumulative Layout Shift | < 0.1 | < 0.25 | > 0.25 |
| Total Blocking Time | < 200ms | < 400ms | > 600ms |
| 总资源大小 | < 500KB | < 1MB | > 2MB |
| 总请求数 | < 30 | < 50 | > 100 |
| Lighthouse Performance | > 90 | > 70 | < 50 |

---

### 三、移动端测试 (Flutter)

#### 3.1 测试框架

**技术选型：**
- `test` (单元测试)
- `flutter_test` (Widget测试)
- `mockito` (Mock对象)
- `integration_test` (集成测试)

**项目结构：**
```
mobile/
├── test/
│   ├── models/
│   │   ├── user_test.dart
│   │   ├── note_test.dart
│   │   └── folder_test.dart
│   ├── services/
│   │   ├── api_service_test.dart
│   │   ├── auth_service_test.dart
│   │   └── profile_service_test.dart
│   ├── screens/
│   │   ├── login_screen_test.dart
│   │   ├── register_screen_test.dart      # 手机号/邮箱注册测试
│   │   ├── note_list_screen_test.dart
│   │   ├── note_edit_screen_test.dart
│   │   ├── profile_screen_test.dart        # 个人信息测试
│   │   └── change_password_screen_test.dart # 修改密码测试
│   └── utils/
│       └── password_validator_test.dart    # 6位数字密码验证测试
├── integration_test/
│   ├── app_test.dart
│   └── profile_flow_test.dart              # 个人信息完整流程测试
└── pubspec.yaml
```

**模型测试示例 (`test/models/note_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/models/note.dart';

void main() {
  group('Note Model', () {
    test('从JSON创建Note对象', () {
      final json = {
        'id': 1,
        'title': '测试笔记',
        'content': '测试内容',
        'folder_id': 1,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final note = Note.fromJson(json);

      expect(note.id, 1);
      expect(note.title, '测试笔记');
      expect(note.content, '测试内容');
      expect(note.folderId, 1);
    });

    test('Note对象转换为JSON', () {
      final note = Note(
        id: 1,
        title: '测试笔记',
        content: '测试内容',
        folderId: 1,
      );

      final json = note.toJson();

      expect(json['title'], '测试笔记');
      expect(json['content'], '测试内容');
    });

    test('Note验证 - 标题不能为空', () {
      final note = Note(title: '', content: '内容');

      expect(note.isValid(), false);
      expect(note.validationError(), '标题不能为空');
    });
  });
}
```

**Service测试示例 (`test/services/api_service_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:your_app/services/api_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      apiService = ApiService(client: mockHttpClient);
    });

    test('获取笔记列表', () async {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        '{"code":200,"data":[{"id":1,"title":"测试"}]}',
        200,
      ));

      final notes = await apiService.getNotes();

      expect(notes.length, 1);
      expect(notes[0].title, '测试');
    });

    test('创建笔记', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"code":200,"data":{"note_id":1}}',
        200,
      ));

      final result = await apiService.createNote(
        title: '新笔记',
        content: '内容',
        folderId: 1,
      );

      expect(result.success, true);
      expect(result.noteId, 1);
    });

    test('401响应抛出认证异常', () async {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        '{"code":401,"message":"未授权"}',
        401,
      ));

      expect(
        () => apiService.getNotes(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('400响应抛出参数错误异常', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"code":400,"message":"请求参数错误"}',
        400,
      ));

      expect(
        () => apiService.createNote(title: '', content: '内容', folderId: 1),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('404响应抛出资源不存在异常', () async {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        '{"code":404,"message":"笔记不存在"}',
        404,
      ));

      expect(
        () => apiService.getNoteById(99999),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('409响应抛出资源冲突异常', () async {
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"code":409,"message":"该手机号已注册"}',
        409,
      ));

      expect(
        () => apiService.registerByPhone(
          phone: '13800138000',
          code: '123456',
          password: '123456',
        ),
        throwsA(isA<ConflictException>()),
      );
    });

    test('500响应抛出服务器错误异常', () async {
      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(
        '{"code":500,"message":"服务器内部错误"}',
        500,
      ));

      expect(
        () => apiService.getNotes(),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
```

**Widget测试示例 (`test/screens/login_screen_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:your_app/screens/login_screen.dart';

void main() {
  testWidgets('登录页面 - 正常登录流程', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));

    // 输入用户名
    final usernameField = find.byKey(Key('username_field'));
    await tester.enterText(usernameField, 'testuser');

    // 输入密码
    final passwordField = find.byKey(Key('password_field'));
    await tester.enterText(passwordField, '123456');

    // 点击登录按钮
    final loginButton = find.byKey(Key('login_button'));
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // 验证跳转到主页
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('登录页面 - 显示错误信息', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));

    // 输入错误凭据
    await tester.enterText(find.byKey(Key('username_field')), 'wronguser');
    await tester.enterText(find.byKey(Key('password_field')), '654321');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // 验证显示错误信息
    expect(find.text('用户名或密码错误'), findsOneWidget);
  });

  testWidgets('登录页面 - 表单验证', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));

    // 直接点击登录（不输入任何内容）
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // 验证显示验证错误
    expect(find.text('请输入用户名'), findsOneWidget);
    expect(find.text('请输入密码'), findsOneWidget);
  });
}
```

**集成测试 (`integration_test/app_test.dart`)：**
```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整用户流程：注册 -> 登录 -> 创建笔记 -> 删除笔记',
      (WidgetTester tester) async {
    // 启动应用
    app.main();
    await tester.pumpAndSettle();

    // 1. 注册新用户
    await tester.tap(find.text('注册'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(Key('register_username')), 'integration_user');
    await tester.enterText(
        find.byKey(Key('register_password')), '123456');
    await tester.enterText(
        find.byKey(Key('register_email')), 'test@example.com');
    await tester.tap(find.byKey(Key('register_button')));
    await tester.pumpAndSettle();

    // 2. 登录
    await tester.enterText(find.byKey(Key('login_username')), 'integration_user');
    await tester.enterText(find.byKey(Key('login_password')), '123456');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // 验证进入主页
    expect(find.byType(HomeScreen), findsOneWidget);

    // 3. 创建目录
    await tester.tap(find.byKey(Key('create_folder_button')));
    await tester.enterText(find.byKey(Key('folder_name_input')), '测试目录');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 4. 创建笔记
    await tester.tap(find.byKey(Key('create_note_button')));
    await tester.enterText(find.byKey(Key('note_title')), '集成测试笔记');
    await tester.enterText(find.byKey(Key('note_content')), '这是测试内容');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验证笔记已创建
    expect(find.text('集成测试笔记'), findsOneWidget);

    // 5. 删除笔记
    await tester.longPress(find.text('集成测试笔记'));
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    // 验证笔记已删除
    expect(find.text('集成测试笔记'), findsNothing);
  });
}
```

**运行Flutter测试命令：**
```bash
# 运行所有单元测试
flutter test

# 运行特定测试文件
flutter test test/models/note_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage

# 运行集成测试（需要模拟器/真机）
flutter test integration_test/app_test.dart

# 运行Widget测试
flutter test test/screens/
```

**Flutter 测试覆盖率目标：**

| 模块 | 单元测试 | Widget测试 | 集成测试 | 总覆盖率 |
|------|----------|------------|----------|----------|
| Models | ≥ 95% | - | - | ≥ 95% |
| Services | ≥ 90% | - | - | ≥ 90% |
| Screens | ≥ 50% | ≥ 80% | - | ≥ 75% |
| Widgets | - | ≥ 85% | - | ≥ 85% |
| 集成测试 | - | - | 核心流程 | 100%覆盖核心流程 |
| **总体** | **≥ 80%** | **≥ 80%** | **100%** | **≥ 80%** |

#### 3.2 更多Widget测试

**笔记列表页面测试 (`test/screens/note_list_screen_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:your_app/screens/note_list_screen.dart';
import 'package:your_app/services/note_service.dart';
import 'package:your_app/models/note.dart';

class MockNoteService extends Mock implements NoteService {}

void main() {
  late MockNoteService mockNoteService;

  setUp(() {
    mockNoteService = MockNoteService();
  });

  testWidgets('笔记列表 - 正确显示笔记', (WidgetTester tester) async {
    // 准备测试数据
    final notes = [
      Note(id: 1, title: '笔记1', content: '内容1', folderId: 1),
      Note(id: 2, title: '笔记2', content: '内容2', folderId: 1),
      Note(id: 3, title: '笔记3', content: '内容3', folderId: 2),
    ];

    when(mockNoteService.getNotes()).thenAnswer((_) async => notes);

    await tester.pumpWidget(MaterialApp(
      home: NoteListScreen(noteService: mockNoteService),
    ));
    await tester.pumpAndSettle();

    // 验证显示所有笔记
    expect(find.text('笔记1'), findsOneWidget);
    expect(find.text('笔记2'), findsOneWidget);
    expect(find.text('笔记3'), findsOneWidget);
  });

  testWidgets('笔记列表 - 空状态显示', (WidgetTester tester) async {
    when(mockNoteService.getNotes()).thenAnswer((_) async => []);

    await tester.pumpWidget(MaterialApp(
      home: NoteListScreen(noteService: mockNoteService),
    ));
    await tester.pumpAndSettle();

    // 验证显示空状态
    expect(find.text('暂无笔记'), findsOneWidget);
    expect(find.byIcon(Icons.note_add), findsOneWidget);
  });

  testWidgets('笔记列表 - 加载状态', (WidgetTester tester) async {
    when(mockNoteService.getNotes()).thenAnswer((_) async => Future.delayed(
      Duration(seconds: 1),
      () => [],
    ));

    await tester.pumpWidget(MaterialApp(
      home: NoteListScreen(noteService: mockNoteService),
    ));

    // 验证显示加载指示器
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // 加载完成后指示器消失
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('笔记列表 - 下拉刷新', (WidgetTester tester) async {
    final notes = [Note(id: 1, title: '笔记', content: '内容', folderId: 1)];
    when(mockNoteService.getNotes()).thenAnswer((_) async => notes);

    await tester.pumpWidget(MaterialApp(
      home: NoteListScreen(noteService: mockNoteService),
    ));
    await tester.pumpAndSettle();

    // 下拉刷新
    await tester.fling(
      find.byType(RefreshIndicator),
      Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    // 验证重新获取了数据
    verify(mockNoteService.getNotes()).called(2);
  });

  testWidgets('笔记列表 - 滚动加载更多', (WidgetTester tester) async {
    final notes = List.generate(
      30,
      (i) => Note(id: i, title: '笔记$i', content: '内容', folderId: 1),
    );

    when(mockNoteService.getNotes(page: 1)).thenAnswer((_) async => notes.sublist(0, 20));
    when(mockNoteService.getNotes(page: 2)).thenAnswer((_) async => notes.sublist(20));

    await tester.pumpWidget(MaterialApp(
      home: NoteListScreen(noteService: mockNoteService),
    ));
    await tester.pumpAndSettle();

    // 验证第一页显示20条
    expect(find.byType(NoteCard), findsNWidgets(20));

    // 滚动到底部触发加载
    await tester.drag(find.byType(ListView), Offset(0, -2000));
    await tester.pumpAndSettle();

    // 验证加载了第二页
    verify(mockNoteService.getNotes(page: 2)).called(1);
  });

  testWidgets('笔记列表 - 左滑删除', (WidgetTester tester) async {
    final notes = [Note(id: 1, title: '待删除', content: '内容', folderId: 1)];
    when(mockNoteService.getNotes()).thenAnswer((_) async => notes);
    when(mockNoteService.deleteNote(1)).thenAnswer((_) async => true);

    await tester.pumpWidget(MaterialApp(
      home: NoteListScreen(noteService: mockNoteService),
    ));
    await tester.pumpAndSettle();

    // 左滑显示删除按钮
    await tester.drag(find.text('待删除'), Offset(-300, 0));
    await tester.pumpAndSettle();

    // 点击删除按钮
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // 验证删除成功
    verify(mockNoteService.deleteNote(1)).called(1);
    expect(find.text('待删除'), findsNothing);
  });
}
```

**笔记编辑页面测试 (`test/screens/note_edit_screen_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:your_app/screens/note_edit_screen.dart';
import 'package:your_app/models/note.dart';
import 'package:your_app/models/folder.dart';

void main() {
  testWidgets('新建笔记 - 表单验证', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: NoteEditScreen(note: null),
    ));

    // 直接点击保存（不填写内容）
    await tester.tap(find.byKey(Key('save_button')));
    await tester.pumpAndSettle();

    // 验证显示验证错误
    expect(find.text('标题不能为空'), findsOneWidget);
  });

  testWidgets('新建笔记 - 正常保存', (WidgetTester tester) async {
    final savedCallback = mockFunction(Note);

    await tester.pumpWidget(MaterialApp(
      home: NoteEditScreen(
        note: null,
        onSaved: savedCallback,
      ),
    ));

    // 填写表单
    await tester.enterText(find.byKey(Key('title_field')), '新笔记');
    await tester.enterText(find.byKey(Key('content_field')), '笔记内容');

    // 点击保存
    await tester.tap(find.byKey(Key('save_button')));
    await tester.pumpAndSettle();

    // 验证回调被调用
    verify(savedCallback(captureAny)).called(1);
  });

  testWidgets('编辑笔记 - 显示已有内容', (WidgetTester tester) async {
    final note = Note(
      id: 1,
      title: '原始标题',
      content: '原始内容',
      folderId: 1,
    );

    await tester.pumpWidget(MaterialApp(
      home: NoteEditScreen(note: note),
    ));

    // 验证显示已有内容
    final titleField = tester.widget<TextField>(find.byKey(Key('title_field')));
    expect(titleField.controller?.text, '原始标题');

    final contentField = tester.widget<TextField>(
      find.byKey(Key('content_field')),
    );
    expect(contentField.controller?.text, '原始内容');
  });

  testWidgets('编辑笔记 - 未修改不保存', (WidgetTester tester) async {
    final note = Note(
      id: 1,
      title: '标题',
      content: '内容',
      folderId: 1,
    );
    final savedCallback = mockFunction(Note);

    await tester.pumpWidget(MaterialApp(
      home: NoteEditScreen(note: note, onSaved: savedCallback),
    ));

    // 直接点击保存（未修改）
    await tester.tap(find.byKey(Key('save_button')));
    await tester.pumpAndSettle();

    // 验证回调未被调用
    verifyNever(savedCallback(any));
  });

  testWidgets('选择目录', (WidgetTester tester) async {
    final folders = [
      Folder(id: 1, name: '工作'),
      Folder(id: 2, name: '学习'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: NoteEditScreen(folders: folders),
    ));

    // 打开目录选择器
    await tester.tap(find.byKey(Key('folder_selector')));
    await tester.pumpAndSettle();

    // 选择"工作"目录
    await tester.tap(find.text('工作'));
    await tester.pumpAndSettle();

    // 验证目录已选择
    expect(find.text('工作'), findsWidgets);
  });
}
```

**主屏幕测试 (`test/screens/home_screen_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:your_app/screens/home_screen.dart';

void main() {
  testWidgets('主屏幕 - 显示目录和笔记', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(),
    ));
    await tester.pumpAndSettle();

    // 验证显示底部导航栏
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('笔记'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('主屏幕 - 切换Tab', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(),
    ));
    await tester.pumpAndSettle();

    // 点击"笔记"Tab
    await tester.tap(find.text('笔记'));
    await tester.pumpAndSettle();

    // 验证切换到笔记页面
    expect(find.byType(NoteListScreen), findsOneWidget);

    // 点击"设置"Tab
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    // 验证切换到设置页面
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('主屏幕 - 浮动按钮创建笔记', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(),
    ));
    await tester.pumpAndSettle();

    // 点击浮动按钮
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // 验证跳转到笔记编辑页面
    expect(find.byType(NoteEditScreen), findsOneWidget);
  });
}
```

**个人信息页面测试 (`test/screens/profile_screen_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:your_app/screens/profile_screen.dart';
import 'package:your_app/services/profile_service.dart';
import 'package:your_app/models/user.dart';

class MockProfileService extends Mock implements ProfileService {}

void main() {
  late MockProfileService mockProfileService;

  setUp(() {
    mockProfileService = MockProfileService();
  });

  testWidgets('个人信息页面 - 显示所有信息', (WidgetTester tester) async {
    final user = User(
      id: 1,
      username: 'testuser',
      phone: '13800138000',
      email: 'test@example.com',
      nickname: '小明',
      avatarUrl: '/uploads/avatars/1.jpg',
      birthday: DateTime(1990, 1, 1),
    );

    when(mockProfileService.getProfile()).thenAnswer((_) async => user);

    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(profileService: mockProfileService),
    ));
    await tester.pumpAndSettle();

    // 验证显示所有信息
    expect(find.text('小明'), findsOneWidget);
    expect(find.text('138****8000'), findsOneWidget);  // 手机号脱敏
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('1990-01-01'), findsOneWidget);
  });

  testWidgets('个人信息页面 - 修改昵称', (WidgetTester tester) async {
    final user = User(
      id: 1,
      username: 'testuser',
      nickname: '小明',
    );

    when(mockProfileService.getProfile()).thenAnswer((_) async => user);
    when(mockProfileService.updateNickname(any)).thenAnswer((_) async => true);

    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(profileService: mockProfileService),
    ));
    await tester.pumpAndSettle();

    // 点击昵称编辑
    await tester.tap(find.byKey(Key('edit_nickname')));
    await tester.pumpAndSettle();

    // 输入新昵称
    await tester.enterText(find.byKey(Key('nickname_input')), '新昵称');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 验证更新成功
    verify(mockProfileService.updateNickname('新昵称')).called(1);
  });

  testWidgets('个人信息页面 - 修改生日（日期选择器）', (WidgetTester tester) async {
    final user = User(id: 1, birthday: DateTime(1990, 1, 1));
    when(mockProfileService.getProfile()).thenAnswer((_) async => user);
    when(mockProfileService.updateBirthday(any)).thenAnswer((_) async => true);

    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(profileService: mockProfileService),
    ));
    await tester.pumpAndSettle();

    // 点击生日
    await tester.tap(find.byKey(Key('edit_birthday')));
    await tester.pumpAndSettle();

    // 验证显示日期选择器
    expect(find.byType(CupertinoDatePicker), findsOneWidget);

    // 选择新日期
    // ...
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 验证更新成功
    verify(mockProfileService.updateBirthday(any)).called(1);
  });

  testWidgets('个人信息页面 - 上传头像', (WidgetTester tester) async {
    final user = User(id: 1, avatarUrl: '/old_avatar.jpg');
    when(mockProfileService.getProfile()).thenAnswer((_) async => user);
    when(mockProfileService.uploadAvatar(any)).thenAnswer((_) async => '/new_avatar.jpg');

    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(profileService: mockProfileService),
    ));
    await tester.pumpAndSettle();

    // 点击头像
    await tester.tap(find.byKey(Key('avatar_image')));
    await tester.pumpAndSettle();

    // 验证显示选项（拍照/从相册选择）
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('从相册选择'), findsOneWidget);
  });
}
```

**密码修改页面测试 (`test/screens/change_password_screen_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:your_app/screens/change_password_screen.dart';

void main() {
  testWidgets('修改密码页面 - 6位数字密码验证', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChangePasswordScreen(),
    ));

    // 输入旧密码
    await tester.enterText(find.byKey(Key('old_password')), '123456');

    // 输入新密码（非6位数字）
    await tester.enterText(find.byKey(Key('new_password')), '12345');
    await tester.enterText(find.byKey(Key('confirm_password')), '12345');

    // 点击确定
    await tester.tap(find.byKey(Key('submit_button')));
    await tester.pumpAndSettle();

    // 验证显示错误信息
    expect(find.text('密码必须为6位数字'), findsOneWidget);
  });

  testWidgets('修改密码页面 - 两次输入不一致', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChangePasswordScreen(),
    ));

    await tester.enterText(find.byKey(Key('old_password')), '123456');
    await tester.enterText(find.byKey(Key('new_password')), '654321');
    await tester.enterText(find.byKey(Key('confirm_password')), '111111');

    await tester.tap(find.byKey(Key('submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('两次输入的密码不一致'), findsOneWidget);
  });

  testWidgets('修改密码页面 - 新密码与旧密码相同', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChangePasswordScreen(),
    ));

    await tester.enterText(find.byKey(Key('old_password')), '123456');
    await tester.enterText(find.byKey(Key('new_password')), '123456');
    await tester.enterText(find.byKey(Key('confirm_password')), '123456');

    await tester.tap(find.byKey(Key('submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('新密码不能与旧密码相同'), findsOneWidget);
  });

  testWidgets('修改密码页面 - 只能输入数字', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChangePasswordScreen(),
    ));

    // 尝试输入字母
    await tester.enterText(find.byKey(Key('new_password')), '12345a');

    // 验证输入被过滤
    final field = tester.widget<TextField>(find.byKey(Key('new_password')));
    expect(field.controller?.text, '12345');
  });
}
```

**密码验证工具测试 (`test/utils/password_validator_test.dart`)：**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/utils/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    test('有效的6位数字密码', () {
      expect(PasswordValidator.validate('123456'), isTrue);
      expect(PasswordValidator.validate('000000'), isTrue);
      expect(PasswordValidator.validate('999999'), isTrue);
    });

    test('无效的密码 - 长度不对', () {
      expect(PasswordValidator.validate('12345'), isFalse);
      expect(PasswordValidator.validate('1234567'), isFalse);
      expect(PasswordValidator.validate(''), isFalse);
    });

    test('无效的密码 - 包含非数字', () {
      expect(PasswordValidator.validate('12345a'), isFalse);
      expect(PasswordValidator.validate('12345!'), isFalse);
      expect(PasswordValidator.validate('12345 '), isFalse);
      expect(PasswordValidator.validate('abcdef'), isFalse);
    });

    test('密码错误信息', () {
      expect(PasswordValidator.getErrorMessage('12345'),
          equals('密码必须为6位数字'));
      expect(PasswordValidator.getErrorMessage('12345a'),
          equals('密码只能包含数字'));
    });
  });
}
```

**个人信息流程集成测试 (`integration_test/profile_flow_test.dart`)：**
```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整个人信息流程', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. 手机号注册
    await tester.tap(find.text('注册'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('register_type_phone')));
    await tester.enterText(find.byKey(Key('phone_input')), '13800138000');
    await tester.tap(find.byKey(Key('send_code_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('code_input')), '123456');
    await tester.enterText(find.byKey(Key('password_input')), '123456');
    await tester.enterText(find.byKey(Key('confirm_password_input')), '123456');
    await tester.enterText(find.byKey(Key('nickname_input')), '小明');
    await tester.tap(find.byKey(Key('register_button')));
    await tester.pumpAndSettle();

    // 验证进入主页
    expect(find.byType(HomeScreen), findsOneWidget);

    // 2. 进入个人信息页面
    await tester.tap(find.byKey(Key('profile_tab')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    // 3. 修改昵称
    await tester.tap(find.byKey(Key('edit_nickname')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('nickname_input')), '新昵称');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('新昵称'), findsOneWidget);

    // 4. 修改生日
    await tester.tap(find.byKey(Key('edit_birthday')));
    await tester.pumpAndSettle();
    // 在日期选择器中选择日期
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    // 5. 修改头像
    await tester.tap(find.byKey(Key('avatar_image')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选择'));
    await tester.pumpAndSettle();
    // 模拟选择图片
    await tester.pumpAndSettle();
    expect(find.byType(CropScreen), findsOneWidget);

    // 6. 修改密码
    await tester.tap(find.byKey(Key('change_password_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('old_password')), '123456');
    await tester.enterText(find.byKey(Key('new_password')), '654321');
    await tester.enterText(find.byKey(Key('confirm_password')), '654321');
    await tester.tap(find.byKey(Key('submit_button')));
    await tester.pumpAndSettle();
    expect(find.text('密码修改成功'), findsOneWidget);

    // 7. 修改手机号（需验证码）
    await tester.tap(find.byKey(Key('edit_phone')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('new_phone_input')), '13900139000');
    await tester.tap(find.byKey(Key('send_code_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('code_input')), '654321');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('139****9000'), findsOneWidget);

    // 8. 修改邮箱（需验证码）
    await tester.tap(find.byKey(Key('edit_email')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('new_email_input')), 'new@example.com');
    await tester.tap(find.byKey(Key('send_code_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(Key('code_input')), '123456');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('new@example.com'), findsOneWidget);
  });

  testWidgets('邮箱注册流程', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('注册'));
    await tester.pumpAndSettle();

    // 切换到邮箱注册
    await tester.tap(find.byKey(Key('register_type_email')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('email_input')), 'user@example.com');
    await tester.tap(find.byKey(Key('send_code_button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('code_input')), '123456');
    await tester.enterText(find.byKey(Key('password_input')), '123456');
    await tester.enterText(find.byKey(Key('confirm_password_input')), '123456');
    await tester.tap(find.byKey(Key('register_button')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
```

#### 3.3 Golden 测试（UI 截图对比）

```dart
// test/golden/login_screen_golden_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:your_app/screens/login_screen.dart';

void main() {
  testGoldens('登录页面 - Golden Test', (tester) async {
    await loadAppFonts();

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));
    await tester.pumpAndSettle();

    // 对比截图
    await screenMatchesGolden(tester, 'login_screen');
  });

  testGoldens('登录页面 - 错误状态', (tester) async {
    await loadAppFonts();

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));

    // 触发错误状态
    await tester.enterText(find.byKey(Key('username_field')), 'wronguser');
    await tester.enterText(find.byKey(Key('password_field')), '654321');
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'login_screen_error');
  });

  testGoldens('登录页面 - 加载状态', (tester) async {
    await loadAppFonts();

    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(),
    ));

    await tester.enterText(find.byKey(Key('username_field')), 'testuser');
    await tester.enterText(find.byKey(Key('password_field')), '123456');
    await tester.tap(find.byKey(Key('login_button')));

    await screenMatchesGolden(tester, 'login_screen_loading');
  });
}
```

#### 3.4 Flutter 性能测试

**性能测试工具：**
- Flutter DevTools (内置)
- `flutter_driver` (自动化性能测试)
- `benchmarking` 包

**安装依赖 (`pubspec.yaml`)：**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
  mockito: ^5.4.0
  golden_toolkit: ^0.15.0
  benchmarking: ^0.1.0
```

**启动性能测试 (`integration_test/startup_benchmark.dart`)：**
```dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'dart:developer' as dev;

void main() {
  group('启动性能测试', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('应用启动时间', () async {
      // 测量启动时间
      final timeline = await driver.traceAction(() async {
        await driver.restart();
        await driver.waitFor(find.byType('MaterialApp'));
      });

      // 计算统计数据
      final average = timeline.averageInMillis;
      final p95 = timeline.percentileInMillis(95);
      final p99 = timeline.percentileInMillis(99);

      dev.log('平均启动时间: ${average}ms');
      dev.log('P95启动时间: ${p95}ms');
      dev.log('P99启动时间: ${p99}ms');

      // 性能断言
      expect(average, lessThan(2000), reason: '平均启动时间应 < 2秒');
      expect(p95, lessThan(3000), reason: 'P95启动时间应 < 3秒');
    });
  });
}
```

**滚动性能测试 (`integration_test/scroll_benchmark.dart`)：**
```dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('滚动性能测试', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();

      // 登录并创建100条笔记用于测试滚动
      await driver.tap(find.byKey(Key('username_field')));
      await driver.enterText('testuser');
      await driver.tap(find.byKey(Key('password_field')));
      await driver.enterText('123456');
      await driver.tap(find.byKey(Key('login_button')));
      await driver.waitFor(find.byType('HomeScreen'));
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('笔记列表滚动流畅度', () async {
      // 导航到笔记列表
      await driver.tap(find.text('笔记'));

      final timeline = await driver.traceAction(() async {
        final listFinder = find.byValueKey('note_list');

        // 快速滚动
        for (int i = 0; i < 5; i++) {
          await driver.scroll(listFinder, 0, -500, Duration(milliseconds: 300));
          await Future.delayed(Duration(milliseconds: 100));
          await driver.scroll(listFinder, 0, 500, Duration(milliseconds: 300));
          await Future.delayed(Duration(milliseconds: 100));
        }
      });

      // 分析帧率
      final frameBuildTimes = timeline.frameBuildTimes;
      final frameRasterTimes = timeline.frameRasterTimes;

      final avgBuildTime = frameBuildTimes.fold<double>(0, (a, b) => a + b) /
          frameBuildTimes.length;
      final avgRasterTime = frameRasterTimes.fold<double>(0, (a, b) => a + b) /
          frameRasterTimes.length;

      // 计算掉帧率
      final droppedFrames = frameBuildTimes.where((t) => t > 16).length;
      final droppedFrameRate = droppedFrames / frameBuildTimes.length;

      print('平均构建时间: ${avgBuildTime}ms');
      print('平均光栅化时间: ${avgRasterTime}ms');
      print('掉帧率: ${(droppedFrameRate * 100).toStringAsFixed(2)}%');

      // 性能断言
      expect(avgBuildTime, lessThan(16), reason: '平均构建时间应 < 16ms (60fps)');
      expect(avgRasterTime, lessThan(16), reason: '平均光栅化时间应 < 16ms');
      expect(droppedFrameRate, lessThan(0.05), reason: '掉帧率应 < 5%');
    });

    test('大量数据渲染性能', () async {
      // 创建1000条笔记
      await driver.tap(find.byKey(Key('create_note_button')));
      for (int i = 0; i < 1000; i++) {
        await driver.tap(find.byKey(Key('title_field')));
        await driver.enterText('笔记$i');
        await driver.tap(find.byKey(Key('content_field')));
        await driver.enterText('内容$i');
        await driver.tap(find.byKey(Key('save_button')));
      }

      // 测量渲染1000条笔记的性能
      final timeline = await driver.traceAction(() async {
        await driver.tap(find.text('笔记'));
        await driver.waitFor(find.byType('NoteListScreen'));
        await driver.waitFor(find.text('笔记0'));
      });

      final renderTime = timeline.totalDuration;
      print('渲染1000条笔记时间: ${renderTime}ms');

      expect(renderTime, lessThan(3000), reason: '渲染时间应 < 3秒');
    });
  });
}
```

**内存性能测试 (`integration_test/memory_benchmark.dart`)：**
```dart
import 'package:flutter_driver/flutter_driver.dart';
import 'dart:developer' as dev;
import 'package:test/test.dart';

void main() {
  group('内存性能测试', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('内存泄漏检测', () async {
      // 登录
      await driver.tap(find.byKey(Key('username_field')));
      await driver.enterText('testuser');
      await driver.tap(find.byKey(Key('password_field')));
      await driver.enterText('123456');
      await driver.tap(find.byKey(Key('login_button')));
      await driver.waitFor(find.byType('HomeScreen'));

      // 获取初始内存使用
      final initialMemory = await driver.getMemoryUsage();
      dev.log('初始内存: ${initialMemory.total} bytes');

      // 反复创建和删除笔记（模拟内存泄漏场景）
      for (int i = 0; i < 50; i++) {
        // 创建笔记
        await driver.tap(find.byKey(Key('create_note_button')));
        await driver.tap(find.byKey(Key('title_field')));
        await driver.enterText('测试笔记$i');
        await driver.tap(find.byKey(Key('content_field')));
        await driver.enterText('内容$i');
        await driver.tap(find.byKey(Key('save_button')));
        await driver.waitFor(find.text('测试笔记$i'));

        // 删除笔记
        await driver.tap(find.byKey(Key('note_menu_$i')));
        await driver.tap(find.text('删除'));
        await driver.tap(find.text('确定'));
      }

      // 获取最终内存使用
      final finalMemory = await driver.getMemoryUsage();
      dev.log('最终内存: ${finalMemory.total} bytes');

      // 计算内存增长
      final memoryGrowth = finalMemory.total - initialMemory.total;
      final growthRate = memoryGrowth / initialMemory.total;

      dev.log('内存增长: $memoryGrowth bytes (${(growthRate * 100).toStringAsFixed(2)}%)');

      // 断言内存增长不应过大（可能存在内存泄漏）
      expect(growthRate, lessThan(0.2),
          reason: '内存增长不应超过初始值的20%');
    });

    test('大图加载内存使用', () async {
      // 测试包含大量图片的笔记
      await driver.tap(find.byKey(Key('note_with_images')));

      final memoryAfterLoad = await driver.getMemoryUsage();
      dev.log('加载图片后内存: ${memoryAfterLoad.total} bytes');

      // 关闭笔记
      await driver.tap(find.byKey(Key('back_button')));

      // 等待GC
      await Future.delayed(Duration(seconds: 2));

      final memoryAfterClose = await driver.getMemoryUsage();
      dev.log('关闭笔记后内存: ${memoryAfterClose.total} bytes');

      // 验证内存已释放
      final memoryReleased = memoryAfterLoad.total - memoryAfterClose.total;
      expect(memoryReleased, greaterThan(0),
          reason: '关闭笔记后应释放内存');
    });
  });
}
```

**帧率监控 (`lib/utils/frame_rate_monitor.dart`)：**
```dart
import 'package:flutter/scheduler.dart';
import 'dart:developer' as dev;

/// 帧率监控器
class FrameRateMonitor {
  static FrameRateMonitor? _instance;
  static FrameRateMonitor get instance =>
      _instance ??= FrameRateMonitor._();

  FrameRateMonitor._();

  int _frameCount = 0;
  int _droppedFrames = 0;
  DateTime? _startTime;
  bool _isMonitoring = false;

  List<double> _frameTimes = [];
  List<double> _fpsHistory = [];

  void start() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _frameCount = 0;
    _droppedFrames = 0;
    _startTime = DateTime.now();
    _frameTimes = [];
    _fpsHistory = [];

    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      if (!_isMonitoring) return;

      final now = DateTime.now();
      final frameTime = now.difference(_startTime!).inMilliseconds.toDouble();

      _frameTimes.add(frameTime);
      _frameCount++;

      // 检测掉帧（超过16.67ms）
      if (_frameTimes.length > 1) {
        final lastDelta = _frameTimes[_frameTimes.length - 1] -
            _frameTimes[_frameTimes.length - 2];
        if (lastDelta > 20) {
          _droppedFrames++;
        }
      }

      // 每秒计算一次FPS
      if (_frameCount % 60 == 0) {
        final elapsed = now.difference(_startTime!).inMilliseconds / 1000;
        final fps = _frameCount / elapsed;
        _fpsHistory.add(fps);
        dev.log('当前FPS: ${fps.toStringAsFixed(2)}, 掉帧数: $_droppedFrames');
      }
    });
  }

  void stop() {
    _isMonitoring = false;
    _reportMetrics();
  }

  void _reportMetrics() {
    if (_fpsHistory.isEmpty) return;

    final avgFps = _fpsHistory.fold<double>(0, (a, b) => a + b) /
        _fpsHistory.length;
    final minFps = _fpsHistory.reduce((a, b) => a < b ? a : b);
    final maxFps = _fpsHistory.reduce((a, b) => a > b ? a : b);
    final droppedFrameRate = _droppedFrames / _frameCount;

    dev.log('\n=== 帧率性能报告 ===');
    dev.log('平均FPS: ${avgFps.toStringAsFixed(2)}');
    dev.log('最低FPS: ${minFps.toStringAsFixed(2)}');
    dev.log('最高FPS: ${maxFps.toStringAsFixed(2)}');
    dev.log('总帧数: $_frameCount');
    dev.log('掉帧数: $_droppedFrames');
    dev.log('掉帧率: ${(droppedFrameRate * 100).toStringAsFixed(2)}%');
  }

  FrameMetrics getMetrics() {
    final avgFps = _fpsHistory.isEmpty
        ? 0.0
        : _fpsHistory.fold<double>(0, (a, b) => a + b) / _fpsHistory.length;

    return FrameMetrics(
      averageFps: avgFps,
      droppedFrames: _droppedFrames,
      totalFrames: _frameCount,
      droppedFrameRate: _frameCount > 0 ? _droppedFrames / _frameCount : 0,
    );
  }
}

class FrameMetrics {
  final double averageFps;
  final int droppedFrames;
  final int totalFrames;
  final double droppedFrameRate;

  FrameMetrics({
    required this.averageFps,
    required this.droppedFrames,
    required this.totalFrames,
    required this.droppedFrameRate,
  });
}
```

#### 3.5 Flutter 压力测试

**快速操作压力测试 (`integration_test/stress_test.dart`)：**
```dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('压力测试', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();

      // 登录
      await driver.tap(find.byKey(Key('username_field')));
      await driver.enterText('testuser');
      await driver.tap(find.byKey(Key('password_field')));
      await driver.enterText('123456');
      await driver.tap(find.byKey(Key('login_button')));
      await driver.waitFor(find.byType('HomeScreen'));
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('快速创建100条笔记', () async {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        // 创建笔记
        await driver.tap(find.byKey(Key('create_note_button')));
        await driver.tap(find.byKey(Key('title_field')));
        await driver.enterText('压力测试笔记$i');
        await driver.tap(find.byKey(Key('content_field')));
        await driver.enterText('内容' * 50);  // 长内容
        await driver.tap(find.byKey(Key('save_button')));

        await driver.waitFor(find.text('压力测试笔记$i'));
      }

      stopwatch.stop();
      print('创建100条笔记耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('平均每条: ${stopwatch.elapsedMilliseconds / 100}ms');

      // 性能要求：每条笔记创建不超过2秒
      expect(stopwatch.elapsedMilliseconds, lessThan(200000));
    });

    test('快速切换Tab 50次', () async {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        await driver.tap(find.text('笔记'));
        await driver.waitFor(find.byType('NoteListScreen'));

        await driver.tap(find.text('目录'));
        await driver.waitFor(find.byType('FolderListScreen'));
      }

      stopwatch.stop();
      print('切换Tab 50次耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('平均每次: ${stopwatch.elapsedMilliseconds / 50}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(50000));
    });

    test('快速编辑同一笔记20次', () async {
      // 先创建一条笔记
      await driver.tap(find.byKey(Key('create_note_button')));
      await driver.tap(find.byKey(Key('title_field')));
      await driver.enterText('快速编辑测试');
      await driver.tap(find.byKey(Key('save_button')));
      await driver.waitFor(find.text('快速编辑测试'));

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 20; i++) {
        // 进入编辑
        await driver.tap(find.text('快速编辑测试'));
        await driver.tap(find.byKey(Key('edit_button')));
        await driver.waitFor(find.byType(NoteEditScreen));

        // 修改内容
        await driver.tap(find.byKey(Key('content_field')));
        await driver.enterText('第$i次修改内容');
        await driver.tap(find.byKey(Key('save_button')));
        await driver.waitFor(find.byType(NoteListScreen));
      }

      stopwatch.stop();
      print('编辑笔记20次耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('平均每次: ${stopwatch.elapsedMilliseconds / 20}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(60000));
    });

    test('大量目录和笔记的渲染性能', () async {
      // 创建50个目录，每个目录20条笔记
      for (int i = 0; i < 50; i++) {
        await driver.tap(find.byKey(Key('create_folder_button')));
        await driver.tap(find.byKey(Key('folder_name_field')));
        await driver.enterText('目录$i');
        await driver.tap(find.byKey(Key('confirm_button')));

        for (int j = 0; j < 20; j++) {
          await driver.tap(find.byKey(Key('create_note_button')));
          await driver.tap(find.byKey(Key('title_field')));
          await driver.enterText('目录$i-笔记$j');
          await driver.tap(find.byKey(Key('folder_selector')));
          await driver.tap(find.text('目录$i'));
          await driver.tap(find.byKey(Key('save_button')));
        }
      }

      // 测试渲染性能
      final timeline = await driver.traceAction(() async {
        await driver.tap(find.text('目录'));
        await driver.waitFor(find.byType('FolderListScreen'));

        // 滚动浏览所有目录
        final listFinder = find.byValueKey('folder_list');
        for (int i = 0; i < 10; i++) {
          await driver.scroll(listFinder, 0, -500, Duration(milliseconds: 300));
          await Future.delayed(Duration(milliseconds: 200));
        }
      });

      final avgFrameTime = timeline.averageFrameBuildTimeMillis;
      print('平均帧构建时间: ${avgFrameTime}ms');
      expect(avgFrameTime, lessThan(16), reason: '应保持60fps');
    });

    test('快速搜索性能', () async {
      // 确保有足够多的笔记
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        await driver.tap(find.byKey(Key('search_button')));
        await driver.tap(find.byKey(Key('search_field')));
        await driver.enterText('关键词$i');
        await driver.waitFor(find.byType('SearchResultScreen'));

        await driver.tap(find.byKey(Key('clear_search')));
      }

      stopwatch.stop();
      print('快速搜索50次耗时: ${stopwatch.elapsedMilliseconds}ms');
      print('平均每次: ${stopwatch.elapsedMilliseconds / 50}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(25000));
    });
  });
}
```

#### 3.6 Flutter 兼容性测试

**多设备测试脚本 (`integration_test/compatibility_test.dart`)：**
```dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// 兼容性测试 - 在不同设备和系统版本上运行
void main() {
  group('兼容性测试', () {

    test('不同屏幕尺寸适配', () async {
      final driver = await FlutterDriver.connect();

      // 测试小屏幕（iPhone SE）
      await driver.setWindowSize(Size(320, 568));
      await _testBasicFlow(driver);

      // 测试标准屏幕（iPhone 13）
      await driver.setWindowSize(Size(390, 844));
      await _testBasicFlow(driver);

      // 测试大屏（iPad）
      await driver.setWindowSize(Size(768, 1024));
      await _testBasicFlow(driver);

      await driver.close();
    });

    test('深色模式兼容', () async {
      final driver = await FlutterDriver.connect();

      // 切换到深色模式
      await driver.setBrightness(Brightness.dark);
      await _testBasicFlow(driver);

      await driver.close();
    });

    test('大字体兼容', () async {
      final driver = await FlutterDriver.connect();

      // 设置大字体
      await driver.setTextScaleFactor(1.5);
      await _testBasicFlow(driver);

      // 设置超大字体
      await driver.setTextScaleFactor(2.0);
      await _testBasicFlow(driver);

      await driver.close();
    });

    test('横屏模式', () async {
      final driver = await FlutterDriver.connect();

      // 旋转到横屏
      await driver.setOrientation(ScreenOrientation.landscape);
      await _testBasicFlow(driver);

      await driver.close();
    });
  });
}

Future<void> _testBasicFlow(FlutterDriver driver) async {
  // 验证登录页面渲染正常
  await driver.waitFor(find.byType(LoginScreen));
  expect(await driver.getText(find.text('登录')), '登录');

  // 执行基本流程
  await driver.tap(find.byKey(Key('username_field')));
  await driver.enterText('testuser');
  await driver.tap(find.byKey(Key('password_field')));
  await driver.enterText('123456');
  await driver.tap(find.byKey(Key('login_button')));

  await driver.waitFor(find.byType(HomeScreen));

  // 验证所有Tab显示正常
  await driver.tap(find.text('目录'));
  await driver.waitFor(find.byType(FolderListScreen));

  await driver.tap(find.text('笔记'));
  await driver.waitFor(find.byType(NoteListScreen));

  await driver.tap(find.text('设置'));
  await driver.waitFor(find.byType(SettingsScreen));
}
```

#### 3.7 Flutter 网络测试

**网络异常测试 (`integration_test/network_test.dart`)：**
```dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('网络测试', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('弱网环境 - 2G网络', () async {
      // 模拟2G网络（需要设备支持）
      await driver.setNetworkProfile(NetworkProfile.threeG);

      final stopwatch = Stopwatch()..start();

      // 登录
      await driver.tap(find.byKey(Key('username_field')));
      await driver.enterText('testuser');
      await driver.tap(find.byKey(Key('password_field')));
      await driver.enterText('123456');
      await driver.tap(find.byKey(Key('login_button')));
      await driver.waitFor(find.byType(HomeScreen));

      stopwatch.stop();
      print('弱网登录耗时: ${stopwatch.elapsedMilliseconds}ms');

      // 应该显示加载指示器
      expect(await driver.waitFor(find.byType(CircularProgressIndicator)),
          isNotNull);
    });

    test('无网络 - 离线模式', () async {
      // 断开网络
      await driver.setNetworkProfile(NetworkProfile.offline);

      // 尝试加载数据
      await driver.tap(find.text('笔记'));
      await driver.waitFor(find.byType(NoteListScreen));

      // 应该显示离线提示或缓存数据
      final hasOfflineMessage = await driver.getText(find.text('网络不可用'));
      final hasCachedData = await driver.getElement(find.byType(NoteCard));

      expect(hasOfflineMessage != null || hasCachedData != null, true);
    });

    test('网络恢复后自动刷新', () async {
      // 先断开网络
      await driver.setNetworkProfile(NetworkProfile.offline);

      // 尝试加载数据（应该失败或显示缓存）
      await driver.tap(find.text('笔记'));
      await driver.waitFor(find.byType(NoteListScreen));

      // 恢复网络
      await driver.setNetworkProfile(NetworkProfile.wifi);

      // 下拉刷新
      await driver.fling(
        find.byType(RefreshIndicator),
        Offset(0, 300),
        1000,
      );
      await driver.pumpAndSettle();

      // 验证数据加载成功
      expect(await driver.waitFor(find.byType(NoteCard)), isNotNull);
    });

    test('API超时处理', () async {
      // 模拟慢网络
      await driver.setNetworkProfile(NetworkProfile.edge);

      // 触发API调用
      await driver.tap(find.text('笔记'));

      // 应该在合理时间内显示超时提示或加载成功
      final timeout = Duration(seconds: 30);
      final result = await driver.waitFor(
        find.byWidgetPredicate((widget) =>
          widget is Text && (
            widget.data?.contains('超时') == true ||
            widget.data?.contains('重试') == true
          )
        ),
        timeout: timeout,
      ).catchError((_) => null);

      // 应该有错误处理
      expect(result != null, true);
    });
  });
}
```

#### 3.8 运行 Flutter 测试命令汇总

```bash
# 1. 运行所有单元测试和Widget测试
flutter test

# 2. 运行特定测试文件
flutter test test/screens/note_list_screen_test.dart

# 3. 生成覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 4. 运行集成测试（需要模拟器）
flutter test integration_test/app_test.dart

# 5. 运行性能测试
flutter drive --driver=test_driver/perf_driver.dart \
  --target=integration_test/startup_benchmark.dart

# 6. 运行Golden测试并更新截图
flutter test --update-goldens

# 7. 运行压力测试
flutter drive --driver=test_driver/stress_driver.dart \
  --target=integration_test/stress_test.dart

# 8. 运行所有测试（一键脚本）
./run_all_tests.sh

# 9. 分析应用大小
flutter build apk --analyze-size
flutter build ios --analyze-size

# 10. 性能分析（使用DevTools）
flutter run --profile
# 然后在浏览器中打开 DevTools: http://localhost:9100
```

**测试脚本 (`run_all_tests.sh`)：**
```bash
#!/bin/bash

echo "======================================"
echo "  运行所有Flutter测试"
echo "======================================"

# 单元测试
echo "📦 运行单元测试..."
flutter test --coverage
if [ $? -ne 0 ]; then
    echo "❌ 单元测试失败"
    exit 1
fi

# Golden测试
echo "🎨 运行Golden测试..."
flutter test --update-goldens
if [ $? -ne 0 ]; then
    echo "❌ Golden测试失败"
    exit 1
fi

# 集成测试
echo "🔗 运行集成测试..."
flutter test integration_test/
if [ $? -ne 0 ]; then
    echo "❌ 集成测试失败"
    exit 1
fi

# 性能测试
echo "⚡ 运行性能测试..."
flutter drive --target=integration_test/startup_benchmark.dart
if [ $? -ne 0 ]; then
    echo "❌ 性能测试失败"
    exit 1
fi

echo "======================================"
echo "  ✅ 所有测试通过！"
echo "======================================"

# 生成报告
echo "📊 生成测试报告..."
genhtml coverage/lcov.info -o coverage/html
echo "覆盖率报告: coverage/html/index.html"
```

**Flutter 性能指标目标：**
| 指标 | 目标值 | 警告值 | 严重值 |
|------|--------|--------|--------|
| 启动时间 | < 2s | < 3s | > 5s |
| 平均帧率 | > 55fps | > 45fps | < 30fps |
| 掉帧率 | < 5% | < 10% | > 20% |
| 内存增长 | < 20% | < 40% | > 60% |
| 页面切换时间 | < 300ms | < 500ms | > 1s |
| 列表滚动流畅度 | > 55fps | > 45fps | < 30fps |
| 应用大小 (Android) | < 30MB | < 50MB | > 80MB |
| 应用大小 (iOS) | < 40MB | < 60MB | > 100MB |

**Flutter 测试覆盖率目标：**
| 模块 | 单元测试 | Widget测试 | 集成测试 | 总覆盖率 |
|------|----------|------------|----------|----------|
| Models | ≥ 95% | - | - | ≥ 95% |
| Services | ≥ 90% | - | - | ≥ 90% |
| Screens | ≥ 50% | ≥ 80% | - | ≥ 75% |
| Widgets | - | ≥ 85% | - | ≥ 85% |
| 集成测试 | - | - | 核心流程 | 100%覆盖核心流程 |
| **总体** | **≥ 80%** | **≥ 80%** | **100%** | **≥ 80%** |

---

## 压测计划 (性能测试)

### 一、后端压测

#### 1.1 Go Benchmark测试

**压测工具：** Go标准库 `testing` + `wrk` + `Apache Bench (ab)`

**压测文件 (`tests/benchmark_test.go`)：**
```go
package tests

import (
    "testing"
    "net/http/httptest"
    "net/http"
    "bytes"
    "encoding/json"
)

// BenchmarkRegisterByPhone 测试手机号注册接口性能
func BenchmarkRegisterByPhone(b *testing.B) {
    db := SetupBenchmarkDB()
    router := SetupBenchmarkRouter(db)

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        phone := "138" + fmt.Sprintf("%08d", i)
        body, _ := json.Marshal(map[string]string{
            "phone":    phone,
            "code":     "123456",  // 测试环境固定验证码
            "password": "123456",
        })

        req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
    }
}

// BenchmarkLogin 测试登录接口性能
func BenchmarkLogin(b *testing.B) {
    db := SetupBenchmarkDB()
    router := SetupBenchmarkRouter(db)

    // 先创建测试用户
    createUser(db, "benchuser", "123456")

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        body, _ := json.Marshal(map[string]string{
            "username": "benchuser",
            "password": "123456",
        })

        req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
    }
}

// BenchmarkCreateNote 测试创建笔记性能
func BenchmarkCreateNote(b *testing.B) {
    db := SetupBenchmarkDB()
    router := SetupBenchmarkRouter(db)
    token := getAuthToken(router)

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        body, _ := json.Marshal(map[string]interface{}{
            "title":     "测试笔记",
            "content":   "测试内容",
            "folder_id": 1,
        })

        req, _ := http.NewRequest("POST", "/api/notes", bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")
        req.Header.Set("Authorization", "Bearer "+token)
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
    }
}

// BenchmarkGetNotes 测试获取笔记列表性能
func BenchmarkGetNotes(b *testing.B) {
    db := SetupBenchmarkDB()
    router := SetupBenchmarkRouter(db)
    token := getAuthToken(router)

    // 预创建100条笔记
    for i := 0; i < 100; i++ {
        createNote(db, "笔记"+string(rune(i)), "内容", 1)
    }

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        req, _ := http.NewRequest("GET", "/api/notes", nil)
        req.Header.Set("Authorization", "Bearer "+token)
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
    }
}

// BenchmarkGetNoteByID 测试获取单个笔记性能
func BenchmarkGetNoteByID(b *testing.B) {
    db := SetupBenchmarkDB()
    router := SetupBenchmarkRouter(db)
    token := getAuthToken(router)

    noteID := createNote(db, "测试笔记", "内容", 1)

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        req, _ := http.NewRequest("GET", "/api/notes/"+string(noteID), nil)
        req.Header.Set("Authorization", "Bearer "+token)
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
    }
}

// BenchmarkUpdateNote 测试更新笔记性能
func BenchmarkUpdateNote(b *testing.B) {
    db := SetupBenchmarkDB()
    router := SetupBenchmarkRouter(db)
    token := getAuthToken(router)

    noteID := createNote(db, "测试笔记", "内容", 1)

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        body, _ := json.Marshal(map[string]interface{}{
            "title":   "更新后的标题",
            "content": "更新后的内容",
        })

        req, _ := http.NewRequest("PUT", "/api/notes/"+string(noteID), bytes.NewBuffer(body))
        req.Header.Set("Content-Type", "application/json")
        req.Header.Set("Authorization", "Bearer "+token)
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
    }
}

// BenchmarkDeleteNote 测试删除笔记性能
func BenchmarkDeleteNote(b *testing.B) {
    db := SetupBenchmarkDB()
    router := SetupBenchmarkRouter(db)
    token := getAuthToken(router)

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        b.StopTimer()
        noteID := createNote(db, "测试笔记", "内容", 1)
        b.StartTimer()

        req, _ := http.NewRequest("DELETE", "/api/notes/"+string(noteID), nil)
        req.Header.Set("Authorization", "Bearer "+token)
        w := httptest.NewRecorder()
        router.ServeHTTP(w, req)
    }
}
```

**运行Go Benchmark：**
```bash
# 运行所有基准测试
go test -bench=. ./tests -benchmem

# 运行特定基准测试
go test -bench=BenchmarkCreateNote ./tests -benchmem

# 指定运行时间和次数
go test -bench=. -benchtime=10s -run=^$ ./tests

# 生成CPU性能分析文件
go test -bench=. -cpuprofile=cpu.prof ./tests
go tool pprof cpu.prof

# 生成内存性能分析文件
go test -bench=. -memprofile=mem.prof ./tests
go tool pprof mem.prof
```

#### 1.2 HTTP压测 (使用wrk)

**压测脚本 (`bench/load_test.lua`)：**
```lua
-- wrk自定义Lua脚本
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Authorization"] = "Bearer YOUR_JWT_TOKEN"

-- 请求体
body = [[
{
    "title": "压测笔记",
    "content": "这是压测内容",
    "folder_id": 1
}
]]

function request()
    wrk.body = body
    return wrk.format(wrk.method, "/api/notes", wrk.headers)
end

-- 统计结果
function done(summary, latency, requests)
    io.write("\n--- 压测结果 ---\n")
    io.write(string.format("总请求数: %d\n", summary.requests))
    io.write(string.format("总字节数: %d bytes\n", summary.bytes))
    io.write(string.format("运行时间: %.2f秒\n", summary.duration / 1000000))
    io.write(string.format("平均延迟: %.2fms\n", latency.mean / 1000))
    io.write(string.format("最大延迟: %.2fms\n", latency.max / 1000))
    io.write(string.format("请求/秒: %.2f\n", summary.requests / (summary.duration / 1000000)))
end
```

**压测命令：**
```bash
# 安装wrk
# macOS
brew install wrk

# 基本压测 - 10个并发连接，持续30秒
wrk -t4 -c10 -d30s http://localhost:8080/api/notes

# 使用Lua脚本压测
wrk -t4 -c10 -d30s -s bench/load_test.lua http://localhost:8080

# 高并发压测 - 100个并发连接
wrk -t4 -c100 -d60s http://localhost:8080/api/notes

# 压测登录接口
wrk -t4 -c50 -d30s -s bench/login_test.lua http://localhost:8080/api/auth/login
```

**Apache Bench (ab) 压测：**
```bash
# 安装Apache Bench (通常随Apache安装)
# macOS自带

# 压测GET接口
ab -n 1000 -c 10 http://localhost:8080/api/notes

# 压测POST接口
ab -n 1000 -c 10 -p data.json -T application/json \
   -H "Authorization: Bearer YOUR_TOKEN" \
   http://localhost:8080/api/notes

# 参数说明：
# -n: 总请求数
# -c: 并发数
# -p: POST数据文件
# -T: Content-Type
# -H: 自定义请求头
```

#### 1.3 压测场景设计

**场景1：登录接口压测**
```bash
# 并发用户数：50
# 持续时间：60秒
# 预期QPS：> 500
# 预期响应时间：< 200ms

wrk -t4 -c50 -d60s -H "Content-Type: application/json" \
    -s bench/login.lua http://localhost:8080/api/auth/login
```

**场景2：笔记CRUD混合压测**
```bash
# 并发用户数：100
# 持续时间：120秒
# 操作分布：
#   - 读取笔记：60%
#   - 创建笔记：20%
#   - 更新笔记：15%
#   - 删除笔记：5%
# 预期QPS：> 1000
# 预期响应时间：< 100ms

wrk -t4 -c100 -d120s -s bench/mixed_ops.lua http://localhost:8080
```

**场景3：高并发读取压测**
```bash
# 并发用户数：200
# 持续时间：60秒
# 目标：测试缓存性能
# 预期QPS：> 2000
# 预期响应时间：< 50ms

wrk -t4 -c200 -d60s http://localhost:8080/api/notes
```

**场景4：批量创建压测**
```bash
# 并发用户数：50
# 每个用户创建100条笔记
# 总请求数：5000
# 预期成功率：> 99%
# 预期响应时间：< 300ms

ab -n 5000 -c 50 -p create_note.json -T application/json \
   -H "Authorization: Bearer YOUR_TOKEN" \
   http://localhost:8080/api/notes
```

#### 1.4 压测指标和阈值

**性能指标：**
```
指标                    | 目标值          | 警告值          | 严重值
------------------------|-----------------|-----------------|----------------
QPS (每秒请求数)        | > 1000          | < 500           | < 200
平均响应时间            | < 100ms         | > 200ms         | > 500ms
P95响应时间             | < 200ms         | > 500ms         | > 1000ms
P99响应时间             | < 500ms         | > 1000ms        | > 2000ms
错误率                  | < 0.1%          | > 1%            | > 5%
CPU使用率               | < 70%           | > 80%           | > 95%
内存使用率              | < 70%           | > 80%           | > 95%
```

**压测报告模板：**
```markdown
# 压测报告

## 测试环境
- CPU: 4核
- 内存: 8GB
- 数据库: SQLite
- Go版本: 1.21

## 测试场景
- 场景名称：笔记CRUD混合压测
- 并发数：100
- 持续时间：120秒

## 测试结果
- 总请求数：120,000
- 成功率：99.8%
- 平均QPS：1,000
- 平均响应时间：85ms
- P95响应时间：150ms
- P99响应时间：280ms

## 性能分析
- CPU峰值：65%
- 内存峰值：512MB
- 数据库连接数：50

## 结论和建议
- 系统性能满足要求
- 建议优化：添加Redis缓存
```

#### 1.5 数据库性能压测

**压测脚本 (`bench/db_benchmark_test.go`)：**
```go
package tests

import (
    "testing"
    "gorm.io/gorm"
)

// BenchmarkDBInsert 测试数据库插入性能
func BenchmarkDBInsert(b *testing.B) {
    db := SetupBenchmarkDB()

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        note := Note{
            UserID:    1,
            FolderID:  1,
            Title:     "测试笔记",
            Content:   "测试内容",
        }
        db.Create(&note)
    }
}

// BenchmarkDBQuery 测试数据库查询性能
func BenchmarkDBQuery(b *testing.B) {
    db := SetupBenchmarkDB()

    // 预创建数据
    for i := 0; i < 1000; i++ {
        db.Create(&Note{
            UserID:  1,
            Title:   "笔记" + string(rune(i)),
            Content: "内容",
        })
    }

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        var notes []Note
        db.Where("user_id = ?", 1).Find(&notes)
    }
}

// BenchmarkDBQueryWithIndex 测试带索引的查询性能
func BenchmarkDBQueryWithIndex(b *testing.B) {
    db := SetupBenchmarkDB()

    // 创建索引
    db.Exec("CREATE INDEX idx_notes_user_id ON notes(user_id)")

    // 预创建数据
    for i := 0; i < 10000; i++ {
        db.Create(&Note{
            UserID:  1,
            Title:   "笔记",
            Content: "内容",
        })
    }

    b.ResetTimer()
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        var notes []Note
        db.Where("user_id = ?", 1).Find(&notes)
    }
}
```

**数据库优化建议：**
```sql
-- 添加索引优化查询性能
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_folder_id ON notes(folder_id);
CREATE INDEX idx_folders_user_id ON folders(user_id);
CREATE INDEX idx_notes_created_at ON notes(created_at);

-- 分析查询性能
EXPLAIN QUERY PLAN SELECT * FROM notes WHERE user_id = 1;
```

---

## 测试和压测执行计划

### 测试执行时间线

**Day 8-9: 单元测试编写**
- 后端单元测试：4小时
- Web端单元测试：3小时
- Flutter单元测试：3小时

**Day 10-11: 集成测试 & E2E测试编写**
- 后端集成测试：4小时
- Web端 Playwright E2E测试：4小时
- Flutter集成测试：4小时

**Day 12: UI/Widget测试 & Golden测试**
- Web端UI组件测试：2小时
- Flutter Widget测试：3小时
- Flutter Golden测试：2小时

**Day 13-14: 性能测试**
- 后端压测脚本编写 + 执行：4小时
- Web端 Lighthouse + k6 压测：4小时
- Flutter 性能测试（启动、滚动、内存）：4小时
- Flutter 压力测试（快速操作、大数据渲染）：4小时

**Day 15: 兼容性测试 & 优化**
- Web端跨浏览器测试：2小时
- Flutter 多设备兼容性测试：3小时
- Flutter 网络异常测试：2小时
- 性能优化：3小时

**总计：约 45 小时（6天）**

### 测试覆盖率要求

| 模块 | 单元测试 | Widget/E2E测试 | 集成测试 | 总覆盖率 |
|------|----------|----------------|----------|----------|
| **后端API** | ≥ 80% | - | ≥ 70% | ≥ 80% |
| **Web前端** | ≥ 75% | ≥ 80% (E2E) | ≥ 70% | ≥ 75% |
| **Flutter** | ≥ 80% | ≥ 80% (Widget) | 100% (核心流程) | ≥ 80% |

### 后端压测通过标准

1. **登录接口**
   - QPS ≥ 500
   - 平均响应时间 ≤ 200ms
   - 错误率 ≤ 0.1%

2. **笔记CRUD接口**
   - QPS ≥ 1000
   - 平均响应时间 ≤ 100ms
   - 错误率 ≤ 0.1%

3. **目录接口**
   - QPS ≥ 800
   - 平均响应时间 ≤ 150ms
   - 错误率 ≤ 0.1%

4. **数据库查询**
   - 单次查询 ≤ 50ms
   - 批量查询(1000条) ≤ 200ms

### Web端性能测试通过标准

1. **Lighthouse 评分**
   - Performance ≥ 90
   - Accessibility ≥ 95
   - Best Practices ≥ 90
   - SEO ≥ 90

2. **Web Vitals 指标**
   - First Contentful Paint (FCP) ≤ 1.5s
   - Largest Contentful Paint (LCP) ≤ 2s
   - Time to Interactive (TTI) ≤ 3s
   - Cumulative Layout Shift (CLS) ≤ 0.1
   - Total Blocking Time (TBT) ≤ 200ms

3. **资源大小**
   - 总资源大小 ≤ 500KB
   - JavaScript 大小 ≤ 200KB
   - CSS 大小 ≤ 100KB
   - 总请求数 ≤ 30

4. **k6 负载测试**
   - 登录接口：100并发，P95 < 500ms，错误率 < 1%
   - 混合操作：80并发，P95 < 500ms，错误率 < 5%
   - 峰值100用户时系统稳定运行

5. **跨浏览器兼容**
   - Chrome (最新2个版本) ✅
   - Firefox (最新2个版本) ✅
   - Safari (最新2个版本) ✅
   - Mobile Chrome ✅
   - Mobile Safari ✅

### Flutter 移动端测试通过标准

1. **启动性能**
   - 冷启动时间 ≤ 2s (P50)
   - 热启动时间 ≤ 1s (P50)
   - 启动时间 P95 ≤ 3s

2. **滚动流畅度**
   - 平均帧率 ≥ 55fps
   - 掉帧率 ≤ 5%
   - 平均帧构建时间 ≤ 16ms
   - 平均光栅化时间 ≤ 16ms

3. **内存使用**
   - 内存增长 ≤ 20% (初始值的)
   - 无明显内存泄漏
   - 大图加载后内存可正确释放

4. **应用大小**
   - Android APK ≤ 30MB
   - iOS IPA ≤ 40MB
   - 无冗余资源

5. **压力测试**
   - 快速创建100条笔记 ≤ 200s (平均2s/条)
   - 快速切换Tab 50次 ≤ 50s (平均1s/次)
   - 快速编辑笔记20次 ≤ 60s (平均3s/次)
   - 大量数据渲染（50目录×20笔记）保持60fps

6. **兼容性**
   - 支持屏幕尺寸：320px ~ 768px 宽度
   - 支持深色/浅色模式 ✅
   - 支持大字体 (1.5x ~ 2.0x) ✅
   - 支持横屏/竖屏 ✅
   - iOS 14+ 和 Android 8+ ✅

7. **网络韧性**
   - 弱网环境（2G/3G）下可正常使用
   - 离线时显示缓存或友好提示
   - 网络恢复后自动刷新
   - API超时（30s）后有错误提示和重试

### 测试质量门禁

**代码提交前必须满足：**
1. ✅ 单元测试全部通过
2. ✅ 代码覆盖率达标
3. ✅ Lint检查无错误
4. ✅ Golden测试截图一致（Flutter）

**发布前必须满足：**
1. ✅ 所有E2E测试通过
2. ✅ 性能测试达标
3. ✅ 压力测试无崩溃
4. ✅ 跨浏览器/多设备测试通过
5. ✅ 内存泄漏检测通过
6. ✅ 安全扫描无高危漏洞

### 测试报告模板

每个模块的测试报告需要包含：

**后端测试报告：**
- 单元测试覆盖率报告
- 集成测试通过情况
- Benchmark 性能数据
- wrk/ab 压测结果
- 数据库性能分析

**Web端测试报告：**
- Jest 覆盖率报告
- Playwright E2E 测试截图/视频
- Lighthouse 评分截图
- k6 压测曲线图
- 资源大小分析报告
- 浏览器兼容性矩阵

**Flutter测试报告：**
- 单元测试覆盖率报告
- Widget 测试通过情况
- Golden 测试截图对比
- Flutter DevTools 性能分析
- 帧率监控报告
- 内存分析报告
- 应用大小分析
- 多设备兼容性矩阵

---

## 下一步行动

确认此计划后，我将按顺序开始实现：

**后端开发：**
1. 创建后端项目结构 + 数据库模型（用户表新增 phone、nickname、avatar_url、birthday 字段）
2. 实现验证码服务（短信/邮件发送）
3. 实现6位数字密码验证 + bcrypt加密工具
4. 开发用户认证API（手机号/邮箱注册 + 登录 + 忘记密码）+ 单元测试
5. 开发笔记和目录管理API + 单元测试
6. 开发个人信息管理API（查看/修改昵称、头像、生日、手机、邮箱、密码）+ 单元测试
7. 实现文件上传服务（头像上传）+ 单元测试
8. 编写后端集成测试 + 压测脚本

**Web端开发：**
9. 开发Web前端（登录/注册页面支持手机号/邮箱 + 6位密码）+ Jest单元测试
10. 开发个人信息页面 + 头像上传 + 修改密码页面
11. 编写Web端 Playwright E2E测试（包含个人信息流程）
12. 编写Web端 Lighthouse + k6 性能测试

**Flutter移动端开发：**
13. 开发Flutter移动端（登录/注册/个人信息页面）+ 单元测试
14. 实现头像上传（image_picker）+ 生日选择器（CupertinoDatePicker）
15. 编写Flutter Widget测试 + 集成测试
16. 编写Flutter 性能测试 + 压力测试

**测试与发布：**
17. 执行全链路压测和优化
18. 生成测试报告

**请确认这个计划是否符合你的需求，或者你是否需要调整任何部分？**
