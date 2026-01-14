#!/bin/bash
exec 2>/dev/null
# 1. 定义路径
CONFIG_FILE="$HOME/.config/linux-wallpaperengine-gui/config.json"
# 这是 Steam 创意工坊 Wallpaper Engine 的默认存放路径
STEAM_WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"

# 2. 从 JSON 中提取壁纸 ID (文件号)
# 使用 jq 处理 JSON。如果没有安装请先: sudo pacman -S jq
WP_ID=$(jq -r '.globalWallpaper' "$CONFIG_FILE")

if [ -z "$WP_ID" ] || [ "$WP_ID" == "null" ]; then
  echo "未发现当前壁纸 ID"
  exit 1
fi

# 3. 构建壁纸文件夹路径并寻找预览图
# Wallpaper Engine 的预览图通常叫 preview.jpg 或 preview.gif
WP_FOLDER="$STEAM_WORKSHOP_DIR/$WP_ID"
PREVIEW_IMG=$(find "$WP_FOLDER" -maxdepth 1 -name "preview.jpg" -o -name "preview.png" -o -name "preview.gif" | head -n 1)

if [ -f "$PREVIEW_IMG" ]; then
  echo "正在根据壁纸 ID [$WP_ID] 的预览图生成颜色..."
  # 4. 运行 Matugen
  matugen image "$PREVIEW_IMG"

  # 5. 可选：由于 Waybar 已经设置了自动重载，这里生成完 colors.css 后它会自动变色
else
  echo "在文件夹 $WP_FOLDER 中未找到预览图片"
fi
