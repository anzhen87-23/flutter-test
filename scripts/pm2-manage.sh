#!/bin/bash

# Personal Notes PM2 管理脚本
# 用于管理后端和前端服务

set -e

# 配置
SERVER="root@39.106.88.210"
APP_DIR="/root/app"
BACKEND_NAME="personal-notes-backend"
WEB_NAME="personal-notes-web"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# 显示帮助
show_help() {
    cat << EOF
Personal Notes PM2 管理脚本

用法: $0 <命令>

命令:
  start          启动所有服务
  stop           停止所有服务
  restart        重启所有服务
  status         查看服务状态
  logs           查看所有日志
  logs-backend   查看后端日志
  logs-web       查看前端日志
  monitor        监控服务
  reload         重载服务（零停机）
  delete         删除所有服务
  reset          重置服务（删除后重新启动）
  save           保存 PM2 配置
  help           显示此帮助信息

示例:
  $0 start              # 启动所有服务
  $0 logs-backend       # 查看后端日志
  $0 status             # 查看服务状态

EOF
}

# 启动服务
cmd_start() {
    info "启动所有服务..."
    ssh "$SERVER" "cd $APP_DIR && pm2 start ecosystem.config.js"
    success "服务已启动"
    sleep 2
    cmd_status
}

# 停止服务
cmd_stop() {
    info "停止所有服务..."
    ssh "$SERVER" "pm2 stop $BACKEND_NAME $WEB_NAME"
    success "服务已停止"
}

# 重启服务
cmd_restart() {
    info "重启所有服务..."
    ssh "$SERVER" "pm2 restart $BACKEND_NAME $WEB_NAME"
    success "服务已重启"
    sleep 2
    cmd_status
}

# 查看状态
cmd_status() {
    info "服务状态："
    echo ""
    ssh "$SERVER" "pm2 status"
    echo ""
}

# 查看所有日志
cmd_logs() {
    info "查看所有日志（Ctrl+C 退出）..."
    ssh "$SERVER" "pm2 logs --lines 50"
}

# 查看后端日志
cmd_logs_backend() {
    info "查看后端日志（Ctrl+C 退出）..."
    ssh "$SERVER" "pm2 logs $BACKEND_NAME --lines 50"
}

# 查看前端日志
cmd_logs_web() {
    info "查看前端日志（Ctrl+C 退出）..."
    ssh "$SERVER" "pm2 logs $WEB_NAME --lines 50"
}

# 监控服务
cmd_monitor() {
    info "启动 PM2 监控（Ctrl+C 退出）..."
    ssh "$SERVER" "pm2 monit"
}

# 重载服务
cmd_reload() {
    info "重载服务（零停机）..."
    ssh "$SERVER" "pm2 reload $BACKEND_NAME $WEB_NAME"
    success "服务已重载"
    sleep 2
    cmd_status
}

# 删除服务
cmd_delete() {
    warn "删除所有服务..."
    ssh "$SERVER" "pm2 delete $BACKEND_NAME $WEB_NAME"
    success "服务已删除"
}

# 重置服务
cmd_reset() {
    warn "重置服务..."
    ssh "$SERVER" << 'EOF'
pm2 delete personal-notes-backend personal-notes-web 2>/dev/null || true
cd /root/app
pm2 start ecosystem.config.js
pm2 save
EOF
    success "服务已重置"
    sleep 2
    cmd_status
}

# 保存配置
cmd_save() {
    info "保存 PM2 配置..."
    ssh "$SERVER" "pm2 save"
    success "配置已保存"
}

# 主逻辑
case "$1" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_restart
        ;;
    status)
        cmd_status
        ;;
    logs)
        cmd_logs
        ;;
    logs-backend)
        cmd_logs_backend
        ;;
    logs-web)
        cmd_logs_web
        ;;
    monitor)
        cmd_monitor
        ;;
    reload)
        cmd_reload
        ;;
    delete)
        cmd_delete
        ;;
    reset)
        cmd_reset
        ;;
    save)
        cmd_save
        ;;
    help|*)
        show_help
        ;;
esac
