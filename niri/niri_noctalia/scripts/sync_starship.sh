#!/bin/bash

# Starship 颜色同步脚本：监听 Noctalia 配置变化，同步颜色到 starship.toml

export PATH=$PATH:/usr/local/bin:/usr/bin:/bin
export WATCH_FILE="$HOME/.config/niri/noctalia.kdl"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
export RELOAD_SIGNAL="$HOME/.cache/starship_reload_signal"

for cmd in entr sed; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "缺少依赖: $cmd"
    exit 1
  fi
done

sleep 3

sync_colors() {
    if [ ! -f "$WATCH_FILE" ]; then return; fi

    # 提取颜色
    COLOR=$(grep "active-color" "$WATCH_FILE" | head -n 1 | cut -d'"' -f2)

    if [[ "$COLOR" =~ ^# ]]; then
        echo "[$(date)] 同步颜色: $COLOR"
        # 更新 starship.toml
        sed -i "s/color_orange = '#[A-Fa-f0-9]*'/color_orange = '$COLOR'/" "$STARSHIP_CONFIG"
        sed -i "s/color_fg0 = '#[A-Fa-f0-9]*'/color_fg0 = '#1b2022'/" "$STARSHIP_CONFIG"

        # 写入信号文件供 Fish 读取
        touch "$RELOAD_SIGNAL"
    fi
}



# 确保监听文件存在
touch "$WATCH_FILE"

# 初始同步
sync_colors

# 核心修复：确保子 shell 可调用函数，并添加 -n 参数
export -f sync_colors
echo "$WATCH_FILE" | /usr/bin/entr -n -p bash -c "sync_colors"
