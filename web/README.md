# Personal Notes Web Frontend

个人笔记应用 Web 前端，基于原生 HTML/CSS/JavaScript 构建的 SPA 应用。

## 技术栈

- **HTML5** + **CSS3** (原生,无框架)
- **JavaScript ES Modules** (原生模块化)
- **Hash 路由** (纯前端 SPA)
- **Jest** (单元测试)
- **Playwright** (E2E 测试)
- **Lighthouse** (性能测试)

## 项目结构

```
web/
├── package.json             # 依赖和脚本配置
├── playwright.config.js     # E2E 测试配置
├── src/
│   ├── index.html           # 主页面
│   ├── css/
│   │   └── style.css        # 全局样式 (响应式)
│   └── js/
│       ├── app.js           # 应用入口
│       ├── router.js        # 路由模块
│       ├── modules/
│       │   ├── api.js       # API 客户端 (认证/笔记/文件夹/个人信息)
│       │   └── ui.js        # UI 工具 (Toast/对话框/验证/防抖)
│       └── pages/
│           ├── login.js         # 登录页
│           ├── register.js      # 注册页 (手机/邮箱)
│           ├── reset-password.js # 重置密码页
│           ├── notes.js         # 笔记列表页
│           ├── note-editor.js   # 笔记编辑页
│           ├── folders.js       # 文件夹管理页
│           └── profile.js       # 个人中心页
├── tests/
│   ├── unit/                # Jest 单元测试 (26个)
│   │   ├── ui.test.js       # UI 工具测试 (16个)
│   │   └── api.test.js      # API 客户端测试 (10个)
│   └── e2e/                 # Playwright E2E 测试
│       ├── auth.spec.js     # 认证流程测试
│       ├── notes.spec.js    # 笔记功能测试
│       ├── profile.spec.js  # 个人中心测试
│       └── full-flow.spec.js # 完整流程测试
└── scripts/
    └── lighthouse.js        # Lighthouse 性能测试
```

## 快速启动

```bash
# 安装依赖
npm install

# 启动后端 (另一个终端)
cd ../backend && go run main.go

# 启动前端
npm run dev   # 访问 http://localhost:3000
```

## 功能页面

| 页面 | 路由 | 说明 |
|------|------|------|
| 登录 | `#/login` | 手机号/邮箱/用户名登录 |
| 注册 | `#/register` | 手机号/邮箱注册,验证码 |
| 重置密码 | `#/reset-password` | 验证码重置 |
| 笔记列表 | `#/notes` | 分页/文件夹筛选 |
| 新建笔记 | `#/note/new` | 编辑器 (自动保存) |
| 编辑笔记 | `#/note/edit/:id` | 编辑/自动保存 |
| 文件夹 | `#/folders` | 创建/重命名/删除 |
| 个人中心 | `#/profile` | 昵称/生日/手机/邮箱/密码/头像 |

## 验证规则 (与后端统一)

- **密码**: 6位纯数字 (`^\d{6}$`)
- **手机号**: 中国大陆11位 (`^1[3-9]\d{9}$`)
- **邮箱**: 标准 email 格式
- **验证码**: 6位数字
- **笔记标题**: ≤200字符
- **头像**: JPG/PNG/GIF, ≤5MB

## 运行测试

```bash
# 单元测试 (26个)
npm test

# E2E 测试
npx playwright install
npm run test:e2e

# E2E 可视化测试
npm run test:e2e:ui

# 性能测试 (需要后端+前端运行)
npm run lighthouse
```

## 测试统计

- **单元测试**: 26 个 (Jest)
  - UI 工具: 16 个
  - API 客户端: 10 个
- **E2E 测试**: ~20 个 (Playwright)
  - 认证流程: 10 个
  - 笔记功能: 7 个
  - 个人中心: 5 个
  - 完整流程: 2 个
- **性能测试**: Lighthouse (性能/可访问性/SEO/最佳实践)

## 特性

- ✅ 纯前端 SPA,无需构建工具
- ✅ 响应式设计 (移动端/桌面端)
- ✅ Hash 路由,支持浏览器前进/后退
- ✅ Token 持久化 (localStorage)
- ✅ 自动登录状态管理
- ✅ 表单验证 (手机号/邮箱/密码/验证码)
- ✅ Toast 消息提示
- ✅ 确认对话框
- ✅ 防抖自动保存
- ✅ XSS 防护 (HTML 转义)
- ✅ 笔记分页 + 文件夹筛选
- ✅ 头像上传
- ✅ 友好空状态展示
