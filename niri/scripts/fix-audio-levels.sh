#!/bin/bash

# 1. 等待 5 秒，确保 PipeWire 和声卡驱动已经完全加载
sleep 5

# 2. 强制解除静音 (unmute) 并把音量推到 100%
# -c 0 代表第一张声卡 (通常是你的 sof-hda-dsp)
# Master, Speaker, Headphone 是你在 alsamixer 里看到的通道名

amixer -c 0 set Master 100% unmute
amixer -c 0 set Speaker 100% unmute
amixer -c 0 set Headphone 100% unmute

# 3. (可选) 如果你有 Bass Speaker，也可以加上这行
amixer -c 0 set 'Bass Speaker' 100% unmute
