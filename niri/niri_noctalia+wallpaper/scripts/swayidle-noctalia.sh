#!/usr/bin/env bash

# 为 noctalia 优化的 swayidle 配置
# 10分钟锁屏，20分钟熄屏，1小时休眠

exec swayidle -w \
timeout 600  'qs -c noctalia-shell ipc call lockScreen lock' \
timeout 1200 'niri msg action power-off-monitors' \
timeout 3600 'systemctl suspend'
