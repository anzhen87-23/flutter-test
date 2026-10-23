# 部署技能使用指南

## 快速开始

使用部署脚本一键部署应用到服务器：

```bash
./scripts/deploy.sh
```

这个脚本会自动完成以下操作：
1. ✅ 提交代码到 Git
2. ✅ 传输文件到服务器 (root@39.106.88.210)
3. ✅ 在服务器上编译后端（启用 CGO 支持 SQLite）
4. ✅ 安装 Web 依赖
5. ✅ 重启 PM2 服务
6. ✅ 运行健康检查和验证测试

## 手动部署步骤

如果需要手动部署，按照以下步骤操作：

### 1. 提交代码
```bash
cd /Users/anzhen/ai-study/flutter-test
git add -A
git commit -m "Deploy: Update application"
git push origin main
```

### 2. 传输文件
```bash
# 传输后端文件
rsync -avz --exclude='personal-notes' --exclude='notes.db' \
  -e "ssh" backend/ root@39.106.88.210:/root/app/backend/

# 传输前端文件
rsync -avz --exclude='node_modules' \
  -e "ssh" web/ root@39.106.88.210:/root/app/web/
```

### 3. 编译后端
```bash
ssh root@39.106.88.210 "cd /root/app/backend && CGO_ENABLED=1 go build -o personal-notes main.go"
```

### 4. 重启服务
```bash
ssh root@39.106.88.210 "cd /root/app && pm2 restart all"
```

### 5. 验证部署
```bash
# 测试后端健康检查
curl http://39.106.88.210:8080/health

# 测试前端访问
curl http://39.106.88.210:3000/
```

## 服务器信息

- **服务器地址:** root@39.106.88.210
- **后端端口:** 8080
- **前端端口:** 3000
- **部署目录:** /root/app
- **日志目录:** /root/app/logs

## 常用 PM2 命令

```bash
# 查看服务状态
ssh root@39.106.88.210 "pm2 status"

# 查看日志
ssh root@39.106.88.210 "pm2 logs"

# 重启所有服务
ssh root@39.106.88.210 "pm2 restart all"

# 停止所有服务
ssh root@39.106.88.210 "pm2 stop all"

# 监控服务
ssh root@39.106.88.210 "pm2 monit"
```

## 故障排查

### 后端无法启动
```bash
# 查看后端日志
ssh root@39.106.88.210 "pm2 logs personal-notes-backend --lines 50"

# 检查二进制文件
ssh root@39.106.88.210 "ls -lh /root/app/backend/personal-notes"

# 检查端口占用
ssh root@39.106.88.210 "netstat -tlnp | grep 8080"
```

### 前端无法访问
```bash
# 查看前端日志
ssh root@39.106.88.210 "pm2 logs personal-notes-web --lines 50"

# 检查 http-server 是否安装
ssh root@39.106.88.210 "which http-server"

# 检查端口占用
ssh root@39.106.88.210 "netstat -tlnp | grep 3000"
```

### 数据库错误
```bash
# 检查数据库文件
ssh root@39.106.88.210 "ls -lh /root/app/backend/notes.db"

# 备份数据库
ssh root@39.106.88.210 "cp /root/app/backend/notes.db /root/app/backend/notes.db.backup"
```

## 回滚操作

如果部署失败，可以回滚到上一个版本：

```bash
# 查看 Git 历史
ssh root@39.106.88.210 "cd /root/app && git log --oneline -5"

# 回滚到上一个版本
ssh root@39.106.88.210 "cd /root/app && git checkout HEAD~1"

# 重新编译后端
ssh root@39.106.88.210 "cd /root/app/backend && CGO_ENABLED=1 go build -o personal-notes main.go"

# 重启服务
ssh root@39.106.88.210 "pm2 restart all"
```

## 部署脚本说明

### deploy.sh 功能详解

1. **代码提交** - 自动检测变更并提交到 Git
2. **文件传输** - 使用 rsync 高效传输文件
3. **后端编译** - 在服务器上编译，启用 CGO 支持 SQLite
4. **依赖安装** - 安装 Web 前端依赖
5. **服务重启** - 使用 PM2 管理进程
6. **健康检查** - 自动验证部署成功

### 环境变量

脚本使用以下配置：
- `SERVER=root@39.106.88.210` - 服务器地址
- `DEPLOY_DIR=/root/app` - 部署目录
- `BACKEND_PORT=8080` - 后端端口
- `WEB_PORT=3000` - 前端端口

## 注意事项

1. **首次部署** - 确保服务器已安装 Go、PM2、http-server
2. **CGO 编译** - 后端必须在服务器上编译，不能交叉编译（SQLite 需要 CGO）
3. **数据库** - 首次启动会自动创建 SQLite 数据库
4. **防火墙** - 确保服务器开放 8080 和 3000 端口
5. **SSH 密钥** - 建议配置 SSH 密钥登录，避免每次输入密码

## 访问地址

部署成功后，可以通过以下地址访问：

- **后端 API:** http://39.106.88.210:8080
- **健康检查:** http://39.106.88.210:8080/health
- **前端页面:** http://39.106.88.210:3000

## 更新日志

- 2026-10-23: 创建自动化部署脚本
- 支持一键部署、健康检查、故障排查
