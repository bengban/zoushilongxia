#!/bin/bash

# 智能截图脚本 - 自动查找 TradingView 窗口
# 如果两个窗口都有 TradingView，优先处理第一个
# 如果只有一个有，处理那个窗口
# 如果都没有，新建窗口打开 TradingView

TIMESTAMP=$(date +%H%M%S)
DATE=$(date +%Y-%m-%d)
SAVE_DIR="screenshots/${DATE}"
TV_URL="https://cn.tradingview.com/chart/RVUjGShv/?symbol=TVC%3AGOLD"

mkdir -p "$SAVE_DIR"

echo "=== TradingView 智能截图脚本 ==="
echo "时间: $(date)"
echo ""

# 检查 Safari 是否运行
if ! pgrep -x "Safari" > /dev/null; then
    echo "Safari 未运行，正在启动并打开 TradingView..."
    open -a Safari "$TV_URL"
    sleep 5
fi

# 查找包含 TradingView 的窗口
echo "正在查找 TradingView 窗口..."

# 使用 osascript 查找并激活 TradingView 窗口
osascript << APPLESCRIPT
set tvURL to "$TV_URL"
set screenshotDir to "$SAVE_DIR"
set timeStamp to "$TIMESTAMP"

tell application "Safari"
    activate
    set windowList to every window
    set tvWindowFound to false
    set targetWindow to missing value
    
    -- 遍历所有窗口查找 TradingView
    repeat with i from 1 to count of windowList
        set currentWindow to item i of windowList
        try
            set windowName to name of currentWindow
            set docURL to ""
            try
                set docURL to URL of current tab of currentWindow
            end try
            
            -- 检查窗口名称或URL是否包含 TradingView 相关关键词
            if windowName contains "GOLD" or windowName contains "TradingView" or windowName contains "RVUjGShv" or docURL contains "tradingview" then
                set targetWindow to currentWindow
                set tvWindowFound to true
                set index of currentWindow to 1  -- 移到最前
                exit repeat
            end if
        on error
            -- 跳过无法访问的窗口
        end try
    end repeat
    
    -- 如果没有找到 TradingView 窗口，新建一个
    if not tvWindowFound then
        tell application "Safari"
            activate
            set newDoc to make new document
            set URL of front document to tvURL
            delay 3
        end tell
    else
        -- 激活找到的窗口
        set index of targetWindow to 1
    end if
    
    delay 2
end tell

-- 截图函数
on captureScreenshot(intervalCode, fileName)
    tell application "Safari"
        activate
        delay 1
        -- 按逗号键打开周期切换对话框
        tell application "System Events"
            keystroke ","
        end tell
        delay 1
        -- 输入周期代码
        tell application "System Events"
            keystroke intervalCode
        end tell
        delay 0.5
        -- 回车确认
        tell application "System Events"
            key code 36
        end tell
        delay 3
    end tell
    
    -- 截图
    do shell script "screencapture -x " & fileName
    delay 1
end captureScreenshot

tell application "Safari"
    activate
    
    -- 截图 30分钟
    my captureScreenshot("30", screenshotDir & "/xau_30m_" & timeStamp & ".png")
    
    -- 截图 5分钟
    my captureScreenshot("5", screenshotDir & "/xau_5m_" & timeStamp & ".png")
    
    -- 截图 1分钟
    my captureScreenshot("1", screenshotDir & "/xau_1m_" & timeStamp & ".png")
end tell

return "截图完成"
APPLESCRIPT

echo ""
echo "=== 截图完成 ==="
echo "文件保存在: $SAVE_DIR/"
ls -lh "$SAVE_DIR"/xau_*_${TIMESTAMP}.png 2>/dev/null || echo "请检查截图文件"
