#!/bin/sh

# --- CPU 使用率 ---
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", 100-$8}')

# --- 内存数据 (百分比与具体数值) ---
mem_info=$(free -k | awk 'NR==2{print $2, $3}')
mem_total_kb=$(echo $mem_info | awk '{print $1}')
mem_used_kb=$(echo $mem_info | awk '{print $2}')
mem_percent=$(( mem_used_kb * 100 / (mem_total_kb + 1) ))
mem_used_gb=$(awk "BEGIN {printf \"%.1f\", $mem_used_kb / 1024 / 1024}")
mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total_kb / 1024 / 1024}")

# --- 磁盘数据 (根分区) ---
df_line=$(df / | awk 'NR==2')
disk_total_kb=$(echo "$df_line" | awk '{print $2}')
disk_used_kb=$(echo "$df_line" | awk '{print $3}')
disk_percent=$(echo "$df_line" | awk '{print $5}' | tr -d '%')
disk_used_gb=$(awk "BEGIN {printf \"%.1f\", $disk_used_kb / 1024 / 1024}")
disk_total_gb=$(awk "BEGIN {printf \"%.1f\", $disk_total_kb / 1024 / 1024}")

# --- CPU 温度 (精准 coretemp) ---
temp_c=$(sensors | grep 'Package id 0' | awk '{print $4}' | tr -d '+°C' | cut -d. -f1)
[ -z "$temp_c" ] && temp_c="N/A"



# ================= 动态 GPU 检测逻辑 (含 VRAM) =================
# AMD Vendor ID = 0x1002
gpu_icon=""
gpu_text=""
gpu_tooltip_line=""

# 1. 扫描 AMD 设备
amd_path=$(grep -l "0x1002" /sys/class/drm/card*/device/vendor 2>/dev/null | head -n1)

if [ -n "$amd_path" ]; then
    # 找到了 AMD 显卡
    card_root=$(dirname $(dirname "$amd_path"))

    # A. 获取 GPU 核心负载
    if [ -f "$card_root/device/gpu_busy_percent" ]; then
        gpu_load=$(cat "$card_root/device/gpu_busy_percent")
        gpu_icon="󰢮 "
        gpu_text="${gpu_load}% " # 状态栏只显示核心负载，保持简洁

        # B. 【新增】获取显存 (VRAM) 使用情况
        # 显存文件通常是 mem_info_vram_used (单位 Bytes)
        if [ -f "$card_root/device/mem_info_vram_used" ]; then
            vram_used_bytes=$(cat "$card_root/device/mem_info_vram_used")
            vram_total_bytes=$(cat "$card_root/device/mem_info_vram_total")

            # 使用 awk 转为 GB (除以 1024^3)
            vram_used_gb=$(awk "BEGIN {printf \"%.1f\", $vram_used_bytes / 1024 / 1024 / 1024}")
            vram_total_gb=$(awk "BEGIN {printf \"%.1f\", $vram_total_bytes / 1024 / 1024 / 1024}")
            vram_str="显存:${vram_used_gb}G/${vram_total_gb}G"
        else
            vram_str=""
        fi

        # C. 拼接 Tooltip (核心负载 + 显存)
        gpu_tooltip_line="\n󰢮 7900 ${vram_str}"
    fi
else
    # 没找到 AMD 显卡，彻底隐藏
    gpu_icon=""
    gpu_text=""
    gpu_tooltip_line=""
fi
# ============================================================



# --- 网络速度 (0.5s 采样) ---
iface=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1)
rx_str="0K"; tx_str="0K"
if [ -n "$iface" ]; then
    read rx1 tx1 < <(awk -v i="$iface:" '$1==i {print $2, $10}' /proc/net/dev)
    sleep 0.5
    read rx2 tx2 < <(awk -v i="$iface:" '$1==i {print $2, $10}' /proc/net/dev)
    rx_kb=$(( (rx2 - rx1) * 2 / 1024 ))
    tx_kb=$(( (tx2 - tx1) * 2 / 1024 ))
    [ $rx_kb -gt 1024 ] && rx_str=$(awk "BEGIN {printf \"%.1fM\", $rx_kb/1024}") || rx_str="${rx_kb}K"
    [ $tx_kb -gt 1024 ] && tx_str=$(awk "BEGIN {printf \"%.1fM\", $tx_kb/1024}") || tx_str="${tx_kb}K"
fi

# --- JSON 输出 ---
text=" ${cpu}% ${gpu_icon}${gpu_text}  ${mem_percent}%  ${rx_str}/s  ${tx_str}/s"
tooltip=" CPU温度: ${temp_c}°C${gpu_tooltip_line}\n 内存: ${mem_used_gb}G/${mem_total_gb}G (${mem_percent}%)\n󰋊 磁盘: ${disk_used_gb}G/${disk_total_gb}G (${disk_percent}%)"
safe_tooltip=$(echo "$tooltip" | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text":"%s","tooltip":"%s","class":"sysmon"}\n' "$text" "$safe_tooltip"
