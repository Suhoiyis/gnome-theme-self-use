#!/bin/bash

LOG_FILE="/tmp/mako-debug.log"
echo "=== $(date) ===" >> "$LOG_FILE"

# --- 1. 获取应用名 (兼容文本解析) ---
RAW_NAME="$MAKO_APP_NAME"
if [ -z "$RAW_NAME" ]; then
    RAW_TEXT=$(makoctl list)
    # 解析 App name
    RAW_NAME=$(echo "$RAW_TEXT" | grep "App name:" | head -n 1 | cut -d: -f2 | xargs)
    # 解析失败兜底取 Summary
    if [ -z "$RAW_NAME" ]; then
         RAW_NAME=$(echo "$RAW_TEXT" | head -n 1 | cut -d: -f2 | xargs)
    fi
fi
echo "目标应用: '$RAW_NAME'" >> "$LOG_FILE"

# --- 2. 映射表：定义搜索词 和 启动命令 ---
# 格式: SEARCH_TERM="搜索关键词"
#       LAUNCH_CMD="启动命令" (如果为空，则不自动启动)

SEARCH_TERM=""
LAUNCH_CMD=""

case "$RAW_NAME" in
    *"Telegram"*)
        SEARCH_TERM="telegram"
        LAUNCH_CMD="telegram-desktop"
        ;;
    *"Chrome"*)
        SEARCH_TERM="chrome"
        LAUNCH_CMD="google-chrome-stable"
        ;;
    *"Firefox"*)
        SEARCH_TERM="firefox"
        LAUNCH_CMD="firefox"
        ;;
    *"Steam"*)
        SEARCH_TERM="steam"
        LAUNCH_CMD="steam"
        ;;
    *"Code"*)
        SEARCH_TERM="code"
        LAUNCH_CMD="code"
        ;;
    *"Kitty"*)
        SEARCH_TERM="kitty"
        LAUNCH_CMD="kitty"
        ;;


# --- QQ (AUR: linuxqq) ---
    *"QQ"*|*"Tencent QQ"*)
        # Niri 里的 app-id 通常是 "qq" 或 "linuxqq"
        SEARCH_TERM="qq"
        # 官方 Linux QQ 的启动命令通常是 linuxqq
        # 如果你装的是其他版本，可能是 "qq"
        LAUNCH_CMD="linuxqq"
        ;;

    # --- 微信 (AUR: wechat / wechat-universal-bwrap) ---
    *"WeChat"*|*"Weixin"*|*"微信"*)
        # Niri 里的 app-id 通常是 "wechat"
        SEARCH_TERM="wechat"
        # 启动命令通常是 wechat
        LAUNCH_CMD="gtk-launch wechat"
        ;;

    # 在这里可以继续添加你常用的软件...
    *)
        # 默认尝试直接用小写名字启动 (碰运气)
        SEARCH_TERM="$RAW_NAME"
        LAUNCH_CMD=$(echo "$RAW_NAME" | awk '{print tolower($0)}')
        ;;
esac

echo "搜索词: '$SEARCH_TERM' | 启动命令: '$LAUNCH_CMD'" >> "$LOG_FILE"

# --- 3. 触发 Mako 默认点击 (让应用知道自己被点了) ---
# 注意：有些应用(如Telegram)即使没窗口，点了invoke可能也会自动启动，
# 但有些应用(如浏览器)可能不会。
makoctl invoke >> "$LOG_FILE" 2>&1

if [ -z "$SEARCH_TERM" ]; then
    echo "❌ 关键词为空，退出" >> "$LOG_FILE"
    makoctl dismiss
    exit 0
fi

# --- 函数：查找窗口 ID ---
get_window_id() {
    niri msg windows | awk -v query="$1" '
        BEGIN { IGNORECASE = 1 }
        /^Window ID/ { gsub(":", "", $3); cid=$3 }
        /App ID:|Title:/ { if ($0 ~ query) { print cid; exit } }
    '
}

# --- 4. 第一次尝试寻找窗口 ---
WINDOW_ID=$(get_window_id "$SEARCH_TERM")

# --- 5. 决策分支 ---
if [ -n "$WINDOW_ID" ]; then
    # A. 找到了窗口 -> 直接聚焦
    echo "✅ 找到现存窗口 -> ID $WINDOW_ID" >> "$LOG_FILE"
    niri msg action focus-window --id "$WINDOW_ID" >> "$LOG_FILE" 2>&1
    sleep 0.1
    niri msg action center-column >> "$LOG_FILE" 2>&1

else
    # B. 没找到窗口 -> 尝试启动
    echo "⚠️ 未找到窗口，准备启动: $LAUNCH_CMD" >> "$LOG_FILE"

    if [ -n "$LAUNCH_CMD" ]; then
        # 后台启动应用 (nohup 保证脚本退出后应用不挂)
        nohup $LAUNCH_CMD >/dev/null 2>&1 &

        # 循环检测：等待窗口出现 (最多等 5 秒)
        for i in {1..10}; do
            sleep 0.5
            WINDOW_ID=$(get_window_id "$SEARCH_TERM")
            if [ -n "$WINDOW_ID" ]; then
                echo "✅ 应用已启动并捕获窗口 -> ID $WINDOW_ID" >> "$LOG_FILE"
                niri msg action focus-window --id "$WINDOW_ID" >> "$LOG_FILE" 2>&1
                sleep 0.1
                niri msg action center-column >> "$LOG_FILE" 2>&1
                break
            fi
        done

        if [ -z "$WINDOW_ID" ]; then
            echo "❌ 启动超时，未检测到新窗口" >> "$LOG_FILE"
        fi
    else
        echo "❌ 未配置启动命令，放弃操作" >> "$LOG_FILE"
    fi
fi

# 最后关闭通知
makoctl dismiss
