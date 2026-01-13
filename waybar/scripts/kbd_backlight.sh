#!/usr/bin/env bash

DEVICE="platform::kbd_backlight"

# 如果带有参数 "next"，则进行档位切换
if [ "$1" == "next" ]; then
    curr=$(brightnessctl -d $DEVICE g)
    next=$(( (curr + 1) % 3 ))
    brightnessctl -d $DEVICE s $next
fi

# 获取当前亮度并输出对应的图标
val=$(brightnessctl -d $DEVICE g)
if [ "$val" -eq "0" ]; then
    echo "󰹐"  # 关
elif [ "$val" -eq "1" ]; then
    echo "󱩒"  # 半亮
else
    echo "󰛨"  # 全亮󰛨
fi
