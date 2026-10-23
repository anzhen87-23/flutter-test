# Personal Notes Backend

个人笔记应用后端 API，基于 Go + Gin + GORM + SQLite。

## 技术栈

- **语言**: Go 1.21+
- **框架**: Gin (HTTP)
- **ORM**: GORM + SQLite
- **认证**: JWT (golang-jwt/jwt/v5, 7天有效期)
- **加密**: bcrypt
- **测试**: testing + testify

## 项目结构

```
backend/
├── main.go              # 入口文件
├── go.mod / go.sum      # 依赖管理
├── handlers/            # HTTP 处理器
│   ├── auth.go          # 认证 (登录/注册/重置密码)
│   ├── note.go          # 笔记 CRUD
│   ├── folder.go        # 文件夹 CRUD
│   ├── profile.go       # 个人信息管理
│   ├── auth_test.go     # 认证测试 (18个)
│   ├── note_test.go     # 笔记测试 (13个)
│   ├── folder_test.go   # 文件夹测试 (10个)
│   ├── profile_test.go  # 个人信息测试 (12个)
│   └── benchmark_test.go # HTTP 压测
├── models/              # 数据模型
│   ├── user.go          # 用户 (手机号脱敏)
│   ├── note.go          # 笔记
│   ├── folder.go        # 文件夹
│   ├── avatar.go        # 头像
│   └── verification_code.go # 验证码
├── utils/               # 工具函数
│   ├── password.go      # 密码验证 (6位数字)
│   ├── phone.go         # 手机号验证/脱敏
│   ├── jwt.go           # JWT 生成/解析
│   ├── verification.go  # 验证码管理
│   ├── password_test.go # 单元测试 (8个)
│   ├── phone_test.go    # 单元测试 (6个)
│   ├── jwt_test.go      # 单元测试 (4个)
│   ├── verification_test.go # 单元测试 (4个)
│   └── benchmark_test.go # 工具基准测试
├── middleware/
│   └── auth.go          # JWT 认证中间件
├── database/
│   └── database.go      # SQLite 初始化
├── routes/
│   └── routes.go        # 路由配置
└── load_test.sh         # HTTP 压测脚本 (wrk)
```

## 快速启动

```bash
# 安装依赖
go mod download

# 运行服务 (默认端口 8080)
go run main.go

# 构建二进制
go build -o personal-notes .
./personal-notes
```

## API 接口

### 认证 (无需登录)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/send-code` | 发送验证码 |
| POST | `/api/auth/register/phone` | 手机号注册 |
| POST | `/api/auth/register/email` | 邮箱注册 |
| POST | `/api/auth/login` | 登录 (手机号/邮箱/用户名) |
| POST | `/api/auth/reset-password` | 重置密码 |

### 笔记 (需要 Bearer Token)

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/notes` | 列表 (支持分页/按文件夹筛选) |
| GET | `/api/notes/:id` | 详情 |
| POST | `/api/notes` | 创建 |
| PUT | `/api/notes/:id` | 更新 |
| DELETE | `/api/notes/:id` | 删除 |

### 文件夹

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/folders` | 列表 (含笔记数量统计) |
| GET | `/api/folders/:id` | 详情 |
| POST | `/api/folders` | 创建 |
| PUT | `/api/folders/:id` | 更新 |
| DELETE | `/api/folders/:id` | 删除 (笔记移至未分类) |

### 个人信息

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/profile` | 获取个人信息 |
| PUT | `/api/profile/nickname` | 修改昵称 |
| PUT | `/api/profile/birthday` | 修改生日 |
| PUT | `/api/profile/phone` | 修改手机号 (需验证码+密码) |
| PUT | `/api/profile/email` | 修改邮箱 (需验证码+密码) |
| PUT | `/api/profile/password` | 修改密码 (需旧密码) |
| POST | `/api/profile/avatar` | 上传头像 (JPG/PNG/GIF, ≤5MB) |

## 验证规则

- **密码**: 6位纯数字 (`^\d{6}$`)
- **手机号**: 中国大陆11位 (`^1[3-9]\d{9}$`)
- **邮箱**: 标准 email 格式
- **验证码**: 6位数字, 5分钟有效, 60秒间隔, 每日10次上限
- **笔记标题**: ≤200字符
- **文件夹名称**: ≤100字符
- **头像**: JPG/PNG/GIF, ≤5MB

## 运行测试

```bash
# 所有测试 (65个)
go test ./... -v

# 仅单元测试
go test ./utils/... -v
go test ./handlers/... -v

# 基准测试
go test ./utils/... -bench=. -benchmem
go test ./handlers/... -bench=. -benchmem

# 带覆盖率
go test ./... -cover

# HTTP 压测 (需要 wrk)
./load_test.sh quick    # 快速测试
./load_test.sh full     # 完整压测套件
```

## 测试统计

- **总测试数**: 65 个
  - 工具函数: 22 个
  - Handler 集成: 43 个
- **基准测试**: 11 个
- **通过率**: 100%

## 性能参考 (Mac M系列)

| 接口 | 操作/秒 | 延迟 |
|------|---------|------|
| 密码验证 | ~20M | ~63ns |
| JWT生成 | ~630K | ~1.9μs |
| JWT解析 | ~377K | ~3.1μs |
| 手机号验证 | ~14M | ~86ns |
| 登录 | ~18 | ~63ms (bcrypt) |

## 数据模型

```
User: id, username, phone*, email*, password, nickname, avatar_url, birthday
Note: id, user_id, folder_id*, title, content
Folder: id, user_id, name
Avatar: id, user_id, file_path, file_size, mime_type
VerificationCode: id, target, code, type, expires_at, used

* 可为 null，phone 在响应中脱敏显示 (138****8000)
```
