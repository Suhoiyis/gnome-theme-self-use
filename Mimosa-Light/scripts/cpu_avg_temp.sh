#!/bin/bash

# 找到 coretemp 对应的 hwmon 目录
HWMON_DIR=""
for d in /sys/class/hwmon/hwmon*; do
    if [ -f "$d/name" ] && [ "$(cat "$d/name")" = "coretemp" ]; then
        HWMON_DIR="$d"
        break
    fi
done

if [ -z "$HWMON_DIR" ]; then
    echo "N/A"
    printf "0" > /tmp/conky_cpu_avg_temp
    exit 1
fi

# 收集所有核心温度（temp2+, 排除 temp1=package）
temps=()
for f in "$HWMON_DIR"/temp[2-9]*_input "$HWMON_DIR"/temp[1-9][0-9]*_input; do
    [ -f "$f" ] || continue
    val=$(cat "$f")
    if [[ "$val" =~ ^[0-9]+$ ]] && [ "$val" -gt 1000 ]; then  # >1°C
        temps+=("$val")
    fi
done

# 计算平均温度（单位：°C）
if [ ${#temps[@]} -eq 0 ]; then
    # 回退到 package 温度
    pkg=$(cat "$HWMON_DIR/temp1_input" 2>/dev/null)
    if [[ "$pkg" =~ ^[0-9]+$ ]]; then
        avg=$((pkg / 1000))
    else
        avg=0
    fi
else
    sum=0
    for t in "${temps[@]}"; do
        sum=$((sum + t))
    done
    avg=$((sum / ${#temps[@]} / 1000))
fi

# === 关键：只输出一次给 Conky，同时写入文件 ===
echo "${avg}°C"                          # ← 给 Conky 文本显示
printf "%d" "$avg" > /tmp/conky_cpu_avg_temp  # ← 给 Lua 圆圈使用（无换行！）