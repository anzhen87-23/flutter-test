#!/bin/bash

# Flutter 应用打包脚本
# 支持 Android (APK + App Bundle) 和 iOS (模拟器 + 真机)

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "未找到命令: $1"
        return 1
    fi
}

# 显示帮助
show_help() {
    cat << EOF
Flutter 应用打包脚本

用法: $0 [选项]

选项:
    --android          仅构建 Android (APK + App Bundle)
    --ios-sim          仅构建 iOS 模拟器版本
    --ios-device       仅构建 iOS 真机版本 (需要 Xcode 配置)
    --ios-install      构建并安装到已连接的 iPhone
    --all              构建所有平台 (Android + iOS 模拟器)
    --help             显示此帮助信息

示例:
    $0 --android       # 只构建 Android
    $0 --all           # 构建所有平台
    $0 --ios-install   # 构建 iOS 并安装到真机

EOF
}

# 构建 Android
build_android() {
    print_info "开始构建 Android..."

    # 检查密钥库是否存在
    if [ ! -f ~/upload-keystore.jks ]; then
        print_warning "未找到密钥库，将使用 debug 签名"
        flutter build apk --release
        flutter build appbundle --release
    else
        flutter build apk --release
        flutter build appbundle --release
    fi

    if [ $? -eq 0 ]; then
        print_success "Android 构建完成"
        echo "  📦 APK: build/app/outputs/flutter-apk/app-release.apk"
        echo "  📦 AAB: build/app/outputs/bundle/release/app-release.aab"
    else
        print_error "Android 构建失败"
        return 1
    fi
}

# 构建 iOS 模拟器
build_ios_simulator() {
    print_info "开始构建 iOS 模拟器版本..."

    flutter build ios --debug --simulator

    if [ $? -eq 0 ]; then
        print_success "iOS 模拟器版本构建完成"
        echo "  📱 App: build/ios/iphonesimulator/Runner.app"
        echo "  💡 提示: 打开 Simulator 并拖拽 App 到模拟器窗口即可安装"
    else
        print_error "iOS 模拟器版本构建失败"
        return 1
    fi
}

# 构建 iOS 真机
build_ios_device() {
    print_info "开始构建 iOS 真机版本..."

    # 获取已连接的 iOS 设备 ID
    DEVICE_ID=$(flutter devices | grep "ios" | grep -oE '[a-f0-9]{40}' | head -1)

    if [ -z "$DEVICE_ID" ]; then
        print_error "未检测到已连接的 iOS 设备"
        print_info "请用 USB 连接 iPhone，并确保已信任此电脑"
        return 1
    fi

    print_info "检测到设备: $DEVICE_ID"

    # 使用 xcodebuild 构建
    cd ios
    xcodebuild -workspace Runner.xcworkspace \
        -scheme Runner \
        -configuration Debug \
        -destination "platform=iOS,id=$DEVICE_ID" \
        -allowProvisioningUpdates \
        CODE_SIGN_STYLE=Automatic \
        | grep -E "(BUILD|error:|warning:)" | tail -20

    if [ $? -eq 0 ]; then
        print_success "iOS 真机版本构建完成"
    else
        print_error "iOS 真机版本构建失败"
        cd ..
        return 1
    fi
    cd ..
}

# 安装到 iOS 设备
install_ios_device() {
    build_ios_device

    if [ $? -ne 0 ]; then
        return 1
    fi

    # 检查 ios-deploy 是否安装
    if ! command -v ios-deploy &> /dev/null; then
        print_info "安装 ios-deploy 工具..."
        brew install ios-deploy
    fi

    DEVICE_ID=$(flutter devices | grep "ios" | grep -oE '[a-f0-9]{40}' | head -1)

    # 查找构建的 app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphoneos -name "Runner.app" -type d 2>/dev/null | head -1)

    if [ -z "$APP_PATH" ]; then
        print_error "未找到构建的 App"
        return 1
    fi

    print_info "安装到设备: $DEVICE_ID"
    ios-deploy --bundle "$APP_PATH" --id "$DEVICE_ID"

    if [ $? -eq 0 ]; then
        print_success "安装完成"
        echo ""
        echo "⚠️  重要: 首次在 iPhone 上打开应用需要信任开发者证书"
        echo "   设置 > 通用 > 设备管理 > 选择你的 Apple ID > 信任"
    else
        print_error "安装失败"
        return 1
    fi
}

# 主逻辑
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    # 切换到项目根目录
    cd "$(dirname "$0")"

    print_info "Flutter 打包脚本启动"
    echo ""

    case "$1" in
        --android)
            build_android
            ;;
        --ios-sim)
            build_ios_simulator
            ;;
        --ios-device)
            build_ios_device
            ;;
        --ios-install)
            install_ios_device
            ;;
        --all)
            build_android
            echo ""
            build_ios_simulator
            ;;
        --help)
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac

    echo ""
    print_success "打包任务完成！"
}

main "$@"
