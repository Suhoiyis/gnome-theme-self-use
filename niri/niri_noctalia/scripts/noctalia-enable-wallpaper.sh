#!/bin/bash
# 启用 Noctalia 壁纸自动化
LOG_FILE="/tmp/noctalia-wallpaper.log"

echo "[$(date)] 启动 noctalia-enable-wallpaper.sh" >> "$LOG_FILE"

SETTINGS_FILE="$HOME/.config/noctalia/settings.json"

# 检查文件是否存在
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "[$(date)] 警告: 配置文件不存在，跳过: $SETTINGS_FILE" >> "$LOG_FILE"
    exit 0
fi

echo "[$(date)] 修改 wallpaper.enabled 为 true" >> "$LOG_FILE"

# 使用 jq 修改 JSON 文件
jq '.wallpaper.enabled = true' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] 成功修改配置文件为: true" >> "$LOG_FILE"
    # 杀死旧的 qs 进程（如果存在），让新的启动命令启动新进程
    killall -9 qs 2>/dev/null || true
    sleep 1
else
    echo "[$(date)] 错误: 修改配置文件失败" >> "$LOG_FILE"
    exit 1
fi

echo "[$(date)] 完成" >> "$LOG_FILE"
