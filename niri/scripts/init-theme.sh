#!/bin/bash

sleep 2

LOG_FILE="/tmp/niri-theme.log"
echo "开始设置主题: $(date)" > "$LOG_FILE"


# 告诉 GTK 框架我们要用什么主题
gsettings set org.gnome.desktop.interface gtk-theme 'MacTahoe-Light' 2>> "$LOG_FILE"
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita-Matugen-A' 2>> "$LOG_FILE"
gsettings set org.gnome.desktop.interface cursor-theme 'MacTahoe' 2>> "$LOG_FILE"
gsettings set org.gnome.desktop.interface cursor-size 24 2>> "$LOG_FILE"
# gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>> "$LOG_FILE" # 如果你是暗色主题，加上这行

# 这一步是为了让旧版 X11 程序也能读到配置 (如果 nwg-look 生成了 .Xresources)
# [ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

echo "设置完成" >> "$LOG_FILE"
