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
text=" ${cpu}%  ${mem_percent}%  ${rx_str}/s  ${tx_str}/s"
tooltip="<b>硬件详情</b>\n CPU温度: ${temp_c}°C\n 内存: ${mem_used_gb}G/${mem_total_gb}G (${mem_percent}%)\n󰋊 磁盘: ${disk_used_gb}G/${disk_total_gb}G (${disk_percent}%)"
safe_tooltip=$(echo "$tooltip" | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text":"%s","tooltip":"%s","class":"sysmon"}\n' "$text" "$safe_tooltip"
