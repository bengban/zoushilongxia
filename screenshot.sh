#!/bin/bash
# ============================================================
# screenshot.sh — 快速多周期截图脚本（对话框输入周期）
#
# 使用说明：
#   bash screenshot.sh           → 截取 30分/5分/1分 三个周期
#   bash screenshot.sh 30m       → 只截 30 分钟图
#   bash screenshot.sh 5m        → 只截 5 分钟图
#   bash screenshot.sh 1m        → 只截 1 分钟图
#
# 截图保存位置：
#   <工作空间>/screenshots/YYYY-MM-DD/xau_<周期>_HHMMSS.png
# ============================================================

WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"
TODAY="$(date '+%Y-%m-%d')"
SCREENSHOT_DIR="${WORKSPACE_DIR}/screenshots/${TODAY}"
TIMESTAMP="$(date '+%H%M%S')"

LOAD_WAIT=3

mkdir -p "${SCREENSHOT_DIR}"

# 周期转数字
period_to_number() {
    case "$1" in
        30m) echo "30" ;;
        5m)  echo "5"  ;;
        1m)  echo "1"  ;;
        *)   echo ""   ;;
    esac
}

# 弹出对话框并输入周期
switch_period_dialog() {
    local period=$1
    local num=$(period_to_number "$period")
    
    osascript << EOF
tell application "Safari"
    activate
    delay 1
end tell
tell application "System Events"
    tell process "Safari"
        -- 按逗号键弹出变更周期对话框
        keystroke ","
        delay 1
        -- 清除现有内容并输入数字
        keystroke "a" using command down
        keystroke "${num}"
        delay 0.5
        -- 按回车确认
        keystroke return
    end tell
end tell
EOF
}

# 切换周期并截图
capture_period() {
    local period=$1
    local outfile="${SCREENSHOT_DIR}/xau_${period}_${TIMESTAMP}.png"

    echo "📸 正在截取 ${period} 周期..."

    # 弹出对话框输入周期
    switch_period_dialog "$period"
    
    # 等待切换
    sleep ${LOAD_WAIT}

    # 截取 Safari 窗口
    local win_id
    win_id=$(osascript -e 'tell application "Safari" to id of window 1')
    screencapture -o -l"${win_id}" "${outfile}"

    if [[ -f "${outfile}" ]]; then
        local size
        size=$(du -sh "${outfile}" | cut -f1)
        echo "   ✅ 已保存：${outfile}（${size}）"
    else
        echo "   ❌ 截图失败：${outfile}"
    fi
}

# 主逻辑
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
    capture_period "$p"
done

echo ""
echo "✅ 所有截图完成！"
echo ""
ls -lh "${SCREENSHOT_DIR}/"
