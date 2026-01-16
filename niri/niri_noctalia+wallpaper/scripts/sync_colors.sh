#!/bin/bash
exec 2>/dev/null
# 1. 定义路径
CONFIG_FILE="$HOME/.config/linux-wallpaperengine-gui/config.json"
STEAM_WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"

# 2. 从 JSON 中提取壁纸 ID
WP_ID=$(jq -r '.globalWallpaper' "$CONFIG_FILE")

if [ -z "$WP_ID" ] || [ "$WP_ID" == "null" ]; then
  echo "未发现当前壁纸 ID"
  exit 1
fi

# 3. 构建路径并寻找预览图（增加 realpath 确保路径绝对化）
WP_FOLDER="$STEAM_WORKSHOP_DIR/$WP_ID"
PREVIEW_IMG=$(find "$WP_FOLDER" -maxdepth 1 \( -name "preview.jpg" -o -name "preview.png" -o -name "preview.gif" \) | head -n 1 | xargs realpath)

# --- 以下是脚本末尾的具体修改部分 ---

if [ -f "$PREVIEW_IMG" ]; then
  echo "正在同步颜色..."

  # A. 运行 Matugen 更新通用变量（用于终端行首等）
  matugen image "$PREVIEW_IMG"

  # B. 获取显示器名称
  # 注意：这里使用了 niri 指令动态获取你的主显示器名
  MONITOR=$(niri msg -j outputs | jq -r 'keys | .[0]')

  # C. 通知 Noctalia 核心变色
  # 必须使用 wallpaper set 而不是 colorScheme set，因为后者不接受路径
  # 这一行会解决你“状态栏、控制中心不变色”以及“报错 not found”的问题
  qs -c noctalia-shell ipc call wallpaper set "$PREVIEW_IMG" "$MONITOR"

else
  echo "在文件夹 $WP_FOLDER 中未找到预览图片"
fi
