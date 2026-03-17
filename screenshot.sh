#!/bin/zsh
# ============================================================
# screenshot.sh — 快速多周期截图脚本（原生 macOS 方案）
# 速度：比 agent-browser 快 3-5 倍
#
# 使用说明：
#   ./screenshot.sh           → 截取 30分/5分/1分 三个周期
#   ./screenshot.sh 30m       → 只截 30 分钟图
#   ./screenshot.sh 5m        → 只截 5 分钟图
#   ./screenshot.sh 1m        → 只截 1 分钟图
#   ./screenshot.sh 30m 5m    → 截 30分+5分
#
# 截图保存位置：
#   <工作空间>/screenshots/YYYY-MM-DD/xau_<周期>_HHmmss.png
#   （已加入 .gitignore，不纳入 Git 提交）
# ============================================================

# ---- 路径配置 ----
# 工作空间根目录（脚本所在目录）
WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"
# 今日日期
TODAY="$(date '+%Y-%m-%d')"
# 截图目录
SCREENSHOT_DIR="${WORKSPACE_DIR}/screenshots/${TODAY}"
# 当前时间戳（用于文件名）
TIMESTAMP="$(date '+%H%M%S')"

# TradingView 图表 URL
BASE_URL="https://cn.tradingview.com/chart/RVUjGShv/?symbol=TVC%3AGOLD"

# 对应各周期的 interval 参数
declare -A INTERVALS
INTERVALS[30m]=30
INTERVALS[5m]=5
INTERVALS[1m]=1

# 等待时间（秒）：等待 TradingView 图表加载
LOAD_WAIT=6

# ---- 初始化截图目录 ----
mkdir -p "${SCREENSHOT_DIR}"

# ---- 切换周期并截图 ----
capture_period() {
    local period=$1
    local interval=${INTERVALS[$period]}
    local outfile="${SCREENSHOT_DIR}/xau_${period}_${TIMESTAMP}.png"

    echo "📸 正在截取 ${period} 周期..."

    # 切换到 TradingView 标签，修改 URL 以切换周期
    osascript << EOF
    tell application "Safari"
        set tvWin to 0
        set tvTab to 0
        repeat with wi from 1 to count of windows
            repeat with ti from 1 to count of tabs of window wi
                if URL of tab ti of window wi contains "tradingview" then
                    set tvWin to wi
                    set tvTab to ti
                end if
            end repeat
        end repeat
        if tvWin is 0 then
            error "未找到 TradingView 标签页，请先在 Safari 中打开。"
        end if
        set current tab of window tvWin to tab tvTab of window tvWin
        set URL of tab tvTab of window tvWin to "${BASE_URL}&interval=${interval}"
    end tell
    tell application "Safari" to activate
EOF

    # 等待页面加载
    sleep ${LOAD_WAIT}

    # 截取 Safari 窗口
    local win_id=$(osascript -e 'tell application "Safari" to id of window 1')
    screencapture -o -l${win_id} "${outfile}"

    if [[ -f "${outfile}" ]]; then
        local size=$(du -sh "${outfile}" | cut -f1)
        echo "   ✅ 已保存：${outfile}（${size}）"
    else
        echo "   ❌ 截图失败：${outfile}"
    fi
}

# ---- 主逻辑 ----
if [[ $# -eq 0 ]]; then
    periods=(30m 5m 1m)
else
    periods=("$@")
fi

echo ""
echo "🔍 开始截图任务（共 ${#periods[@]} 个周期）"
echo "   保存目录：${SCREENSHOT_DIR}/"
echo ""

for p in "${periods[@]}"; do
    if [[ -z "${INTERVALS[$p]}" ]]; then
        echo "❓ 未知周期 '$p'，跳过。支持：30m / 5m / 1m"
    else
        capture_period "$p"
    fi
done

echo ""
echo "✅ 所有截图完成！"
echo ""
ls -lh "${SCREENSHOT_DIR}/"
