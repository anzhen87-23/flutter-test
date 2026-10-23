#!/bin/bash
# Personal Notes API 压测脚本
# 使用方法: ./load_test.sh [命令]
# 命令: quick | full | login | register | notes | report

BASE_URL="http://localhost:8080"
RESULTS_DIR="./load_test_results"
mkdir -p "$RESULTS_DIR"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查依赖
check_deps() {
    if ! command -v wrk &> /dev/null; then
        log_error "wrk 未安装。请运行: brew install wrk (macOS) 或 apt install wrk (Linux)"
        exit 1
    fi
}

# 注册测试用户并获取Token
setup_test_user() {
    log_info "创建测试用户..."

    # 发送验证码
    SEND_CODE=$(curl -s -X POST "$BASE_URL/api/auth/send-code" \
        -H "Content-Type: application/json" \
        -d '{"target":"13800008000","type":"register"}')

    # 由于验证码在控制台输出，这里用Go测试直接创建
    # 或者通过登录已有用户
    LOGIN=$(curl -s -X POST "$BASE_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"account":"13800008000","password":"123456"}')

    TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

    if [ -z "$TOKEN" ]; then
        log_error "获取Token失败。请先通过正常途径注册用户。"
        log_info "或使用基准测试: go test ./handlers/... -bench=. -benchmem"
        exit 1
    fi

    echo "$TOKEN" > "$RESULTS_DIR/.token"
    log_info "Token已保存"
}

# 健康检查压测
bench_health() {
    log_info "压测: 健康检查接口 (GET /health)"
    wrk -t4 -c100 -d10s "$BASE_URL/health" \
        -H "Connection: keep-alive" \
        | tee "$RESULTS_DIR/health.txt"
    log_info "结果已保存到 $RESULTS_DIR/health.txt"
}

# 登录接口压测
bench_login() {
    log_info "压测: 登录接口 (POST /api/auth/login)"

    cat > "$RESULTS_DIR/login.lua" << 'EOF'
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
wrk.body = '{"account":"13800008000","password":"123456"}'
EOF

    wrk -t4 -c50 -d30s -s "$RESULTS_DIR/login.lua" "$BASE_URL/api/auth/login" \
        | tee "$RESULTS_DIR/login.txt"
}

# 笔记列表压测（需要Token）
bench_list_notes() {
    TOKEN=$(cat "$RESULTS_DIR/.token" 2>/dev/null)
    if [ -z "$TOKEN" ]; then
        setup_test_user
        TOKEN=$(cat "$RESULTS_DIR/.token")
    fi

    log_info "压测: 笔记列表接口 (GET /api/notes)"

    cat > "$RESULTS_DIR/notes.lua" << EOF
wrk.headers["Authorization"] = "Bearer $TOKEN"
EOF

    wrk -t4 -c50 -d30s -s "$RESULTS_DIR/notes.lua" "$BASE_URL/api/notes" \
        | tee "$RESULTS_DIR/notes.txt"
}

# 创建笔记压测
bench_create_note() {
    TOKEN=$(cat "$RESULTS_DIR/.token" 2>/dev/null)
    if [ -z "$TOKEN" ]; then
        setup_test_user
        TOKEN=$(cat "$RESULTS_DIR/.token")
    fi

    log_info "压测: 创建笔记接口 (POST /api/notes)"

    cat > "$RESULTS_DIR/create_note.lua" << EOF
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Authorization"] = "Bearer $TOKEN"
wrk.body = '{"title":"Load Test Note","content":"Content for load testing"}'
EOF

    wrk -t4 -c50 -d30s -s "$RESULTS_DIR/create_note.lua" "$BASE_URL/api/notes" \
        | tee "$RESULTS_DIR/create_note.txt"
}

# 完整压测套件
bench_full() {
    check_deps
    log_info "=== 开始完整压测套件 ==="

    # 先确保服务运行
    if ! curl -s "$BASE_URL/health" > /dev/null; then
        log_error "服务未运行。请先启动: go run main.go"
        exit 1
    fi

    setup_test_user

    echo ""
    echo "=============================="
    echo "1/4 健康检查压测"
    echo "=============================="
    bench_health

    echo ""
    echo "=============================="
    echo "2/4 登录接口压测"
    echo "=============================="
    bench_login

    echo ""
    echo "=============================="
    echo "3/4 笔记列表压测"
    echo "=============================="
    bench_list_notes

    echo ""
    echo "=============================="
    echo "4/4 创建笔记压测"
    echo "=============================="
    bench_create_note

    echo ""
    log_info "=== 压测完成！结果保存在 $RESULTS_DIR/ ==="
    generate_report
}

# 生成报告
generate_report() {
    log_info "生成压测报告..."

    REPORT="$RESULTS_DIR/REPORT.md"
    echo "# Personal Notes API 压测报告" > "$REPORT"
    echo "" >> "$REPORT"
    echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT"
    echo "" >> "$REPORT"

    for f in health login notes create_note; do
        if [ -f "$RESULTS_DIR/$f.txt" ]; then
            echo "## $f" >> "$REPORT"
            echo '```' >> "$REPORT"
            cat "$RESULTS_DIR/$f.txt" >> "$REPORT"
            echo '```' >> "$REPORT"
            echo "" >> "$REPORT"
        fi
    done

    log_info "报告已生成: $REPORT"
}

# 快速压测
bench_quick() {
    check_deps
    log_info "快速压测（健康检查 5秒）"
    wrk -t2 -c10 -d5s "$BASE_URL/health"
}

# 主入口
case "${1:-quick}" in
    quick)      bench_quick ;;
    full)       bench_full ;;
    login)      check_deps; bench_login ;;
    notes)      check_deps; bench_list_notes ;;
    create)     check_deps; bench_create_note ;;
    health)     check_deps; bench_health ;;
    report)     generate_report ;;
    *)
        echo "用法: $0 [quick|full|login|notes|create|health|report]"
        exit 1
        ;;
esac
