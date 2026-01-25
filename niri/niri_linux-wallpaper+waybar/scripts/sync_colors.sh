#!/bin/bash

# 颜色同步脚本：精准读取 active_monitors 并同步颜色

# 1. 定义配置文件路径
export CONFIG_FILE="$HOME/.config/linux-wallpaperengine-gui/config.json"

# 2. 检查依赖
for cmd in jq matugen niri qs entr; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "缺少依赖: $cmd"
    exit 1
  fi
done

sync_colors() {
    # 等待配置文件出现
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "配置文件未找到，跳过..."
        return
    fi

    # --- 关键修改：先获取显示器名称 ---
    # 我们假设主显示器是列表里的第一个
    local MONITOR
    MONITOR=$(niri msg -j outputs | jq -r 'keys | .[0] // "eDP-1"')
    
    echo "DEBUG: 检测到显示器: $MONITOR"

    # --- 关键修改：读取壁纸 ID 的优先级逻辑 ---
    # 1. 尝试从 active_monitors 读取当前屏幕的壁纸
    # 2. 如果没有，读取 lastWallpaper (最后一次设置的)
    # 3. 最后才读取 globalWallpaper
    local WP_ID
    WP_ID=$(jq -r --arg mon "$MONITOR" '
        .active_monitors[$mon] // 
        .lastWallpaper // 
        .globalWallpaper // 
        empty
    ' "$CONFIG_FILE")

    if [ -z "$WP_ID" ]; then
        echo "DEBUG: 未找到有效的壁纸 ID"
        return
    fi

    echo "DEBUG: 锁定壁纸 ID: $WP_ID"

    # --- 获取创意工坊路径 ---
    # 优先从配置文件读取 workshopPath，如果没有则使用默认路径
    local WORKSHOP_PATH
    WORKSHOP_PATH=$(jq -r '.workshopPath // empty' "$CONFIG_FILE")
    if [ -z "$WORKSHOP_PATH" ]; then
        WORKSHOP_PATH="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
    fi

    local WP_FOLDER="$WORKSHOP_PATH/$WP_ID"
    if [ ! -d "$WP_FOLDER" ]; then
        echo "DEBUG: 壁纸目录不存在: $WP_FOLDER"
        return
    fi

    # --- 查找预览图 ---
    local PREVIEW_IMG
    PREVIEW_IMG=$(find "$WP_FOLDER" -maxdepth 1 \( -name "preview.jpg" -o -name "preview.png" -o -name "preview.gif" \) | head -n 1)

    if [ -z "$PREVIEW_IMG" ]; then
        echo "DEBUG: 未找到预览图"
        return
    fi

    echo "正在同步颜色..."
    echo "  - 图片: $PREVIEW_IMG"
    
    # 1. 生成系统主题色
    matugen image "$PREVIEW_IMG"

    # 2. 设置 Noctalia 壁纸
    # 使用 realpath 确保路径绝对正确
    ABS_IMG=$(realpath "$PREVIEW_IMG")
    if qs -c noctalia-shell ipc call wallpaper set "$ABS_IMG" "$MONITOR"; then
        echo "  - Noctalia 壁纸设置成功"
    else
        echo "  - Noctalia IPC 调用失败 (可能 Noctalia 未启动)"
    fi

    echo "✅ 颜色同步完成"
}

# 导出变量和函数供 entr 使用
export -f sync_colors

# 初始运行一次
sync_colors

# 持续监听
echo "开始监听配置文件: $CONFIG_FILE"
echo "$CONFIG_FILE" | /usr/bin/entr -n -p bash -c "sync_colors"
