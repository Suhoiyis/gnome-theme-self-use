#!/usr/bin/env bash

# 10分钟锁屏，20分钟熄屏，60分钟休眠
exec swayidle -w \
timeout 600  'swaylock -f' \
timeout 1200  'niri msg action power-off-monitors' \
resume       'niri msg action power-on-monitors' \
timeout 3600 'systemctl suspend'
