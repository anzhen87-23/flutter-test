#!/bin/bash

# Android 真机调试脚本
# 支持设备检测、构建、安装、调试、日志查看

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_APP_DIR="$PROJECT_ROOT/flutter_app"

# 打印函数
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 显示帮助
show_help() {
    cat << EOF
Android 真机调试脚本

用法: $0 [命令]

命令:
    check       检查设备连接状态
    install     构建并安装 debug APK
    run         运行应用（支持热重载）
    logs        查看应用日志
    clear       清除应用数据
    uninstall   卸载应用
    restart     重启 ADB 服务
    help        显示此帮助信息

示例:
    $0 check        # 检查设备
    $0 run          # 运行调试（推荐）
    $0 logs         # 查看日志

EOF
}

# 检查设备连接
check_device() {
    print_info "检查 Android 设备连接..."

    # 尝试多个 adb 路径
    ADB_CMD=""
    if command -v adb &> /dev/null; then
        ADB_CMD="adb"
    elif [ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
        ADB_CMD="$HOME/Library/Android/sdk/platform-tools/adb"
    else
        print_error "未找到 adb 命令"
        return 1
    fi

    # 获取设备列表
    DEVICES=$($ADB_CMD devices 2>&1 | grep -v "List of devices" | grep "device$" || true)

    if [ -z "$DEVICES" ]; then
        print_error "未检测到 Android 设备"
        echo ""
        echo "请按以下步骤操作："
        echo "1. 手机上开启：设置 > 开发者选项 > USB 调试"
        echo "2. USB 连接模式选择：文件传输（MTP）"
        echo "3. 手机上点击：允许 USB 调试"
        echo "4. 重新连接 USB 线"
        echo ""
        echo "尝试重启 ADB："
        echo "  $0 restart"
        return 1
    fi

    # 显示设备信息
    print_success "检测到设备："
    echo "$DEVICES" | while read line; do
        DEVICE_ID=$(echo $line | awk '{print $1}')
        print_info "设备 ID: $DEVICE_ID"

        # 获取设备型号
        MODEL=$($ADB_CMD -s $DEVICE_ID shell getprop ro.product.model 2>/dev/null || echo "Unknown")
        ANDROID_VERSION=$($ADB_CMD -s $DEVICE_ID shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")

        echo "   型号: $MODEL"
        echo "   Android 版本: $ANDROID_VERSION"
    done

    return 0
}

# 重启 ADB 服务
restart_adb() {
    print_info "重启 ADB 服务..."

    ADB_CMD="adb"
    if ! command -v adb &> /dev/null; then
        ADB_CMD="$HOME/Library/Android/sdk/platform-tools/adb"
    fi

    $ADB_CMD kill-server
    sleep 1
    $ADB_CMD start-server
    sleep 2

    print_success "ADB 服务已重启"
    check_device
}

# 构建并安装 debug APK
install_app() {
    check_device || return 1

    print_info "构建 debug APK..."
    cd "$FLUTTER_APP_DIR"

    flutter build apk --debug 2>&1 | tail -10

    if [ $? -ne 0 ]; then
        print_error "构建失败"
        return 1
    fi

    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"

    if [ ! -f "$APK_PATH" ]; then
        print_error "APK 文件不存在: $APK_PATH"
        return 1
    fi

    print_info "安装到设备..."
    adb install -r "$APK_PATH"

    if [ $? -eq 0 ]; then
        print_success "安装成功"
    else
        print_error "安装失败"
        return 1
    fi
}

# 运行应用（支持热重载）
run_app() {
    check_device || return 1

    print_info "启动 Flutter 调试模式..."
    cd "$FLUTTER_APP_DIR"

    # 获取设备 ID
    DEVICE_ID=$(adb devices | grep "device$" | head -1 | awk '{print $1}')

    if [ -z "$DEVICE_ID" ]; then
        print_error "未找到设备"
        return 1
    fi

    print_success "在设备上运行应用（支持热重载）"
    echo ""
    echo "快捷键："
    echo "  r - 热重载"
    echo "  R - 热重启"
    echo "  q - 退出"
    echo "  h - 显示更多帮助"
    echo ""

    flutter run -d "$DEVICE_ID"
}

# 查看应用日志
view_logs() {
    check_device || return 1

    print_info "查看应用日志..."
    echo ""
    echo "按 Ctrl+C 退出日志查看"
    echo ""

    # 清除旧日志
    adb logcat -c

    # 显示 Flutter 应用日志
    adb logcat -v time | grep -E "flutter|dart|AndroidRuntime" --line-buffered
}

# 清除应用数据
clear_app_data() {
    check_device || return 1

    PACKAGE_NAME="com.an.zhen"

    print_info "清除应用数据: $PACKAGE_NAME"

    adb shell pm clear "$PACKAGE_NAME"

    if [ $? -eq 0 ]; then
        print_success "应用数据已清除"
    else
        print_error "清除失败"
        return 1
    fi
}

# 卸载应用
uninstall_app() {
    check_device || return 1

    PACKAGE_NAME="com.an.zhen"

    print_info "卸载应用: $PACKAGE_NAME"

    adb uninstall "$PACKAGE_NAME"

    if [ $? -eq 0 ]; then
        print_success "应用已卸载"
    else
        print_error "卸载失败（可能未安装）"
        return 1
    fi
}

# 主逻辑
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    case "$1" in
        check)
            check_device
            ;;
        install)
            install_app
            ;;
        run)
            run_app
            ;;
        logs)
            view_logs
            ;;
        clear)
            clear_app_data
            ;;
        uninstall)
            uninstall_app
            ;;
        restart)
            restart_adb
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
