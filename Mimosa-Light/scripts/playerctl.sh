#!/bin/bash

# 安全截取并添加省略号（UTF-8 安全）
safe_truncate_with_ellipsis() {
    local text="$1"
    local max_len="${2:-30}"

    # 如果文本为空或长度不足，直接返回
    if [ -z "$text" ] || [ "${#text}" -le "$max_len" ]; then
        printf '%s' "$text"
        return
    fi

    # 优先使用 python3（100% Unicode 安全）
    if command -v python3 >/dev/null 2>&1; then
        printf '%s' "$text" | python3 -c "
import sys
s = sys.stdin.read()
max_len = $max_len
if len(s) <= max_len:
    print(s, end='')
else:
    # 使用 Unicode 省略号 '…' (U+2026)
    print(s[:max_len-1] + '…', end='')
"
    else
        # fallback: 使用 cut -c（可能不完美，但尽量）
        truncated=$(printf '%s' "$text" | cut -c "1-$((max_len - 1))" 2>/dev/null)
        if [ -n "$truncated" ]; then
            printf '%s…' "$truncated"
        else
            printf '%s' "$text" | cut -c "1-$max_len"
        fi
    fi
}

status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
    # 获取原始元数据
    artist_raw=$(playerctl metadata xesam:artist 2>/dev/null)
    album_raw=$(playerctl metadata xesam:album 2>/dev/null)
    title_raw=$(playerctl metadata xesam:title 2>/dev/null)

    # 安全截取（带省略号）
    artist=$(safe_truncate_with_ellipsis "$artist_raw" 20)
    album=$(safe_truncate_with_ellipsis "$album_raw" 25)
    title=$(safe_truncate_with_ellipsis "$title_raw" 14)  # 歌名稍短，因常含括号

    length_us=$(playerctl metadata mpris:length 2>/dev/null)
    position_sec=$(playerctl position 2>/dev/null)

    MAX_LENGTH_US=86400000000  # 24 小时（微秒）

    # 格式化当前位置（秒，支持小数）
    format_time_from_sec() {
        local s=$1
        if [[ $s =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            awk -v sec="$s" 'BEGIN {
                mins = int(sec / 60)
                secs = int(sec % 60)
                printf "%d:%02d", mins, secs
            }'
        else
            echo "0:00"
        fi
    }

    # 格式化总时长（微秒 → 分:秒），无效则返回空
    format_time_from_us() {
        local us=$1
        if [[ $us =~ ^[0-9]+$ ]] && [ "$us" -gt 0 ] && [ "$us" -le $MAX_LENGTH_US ]; then
            sec=$((us / 1000000))
            awk -v s="$sec" 'BEGIN {
                mins = int(s / 60)
                secs = int(s % 60)
                printf "%d:%02d", mins, secs
            }'
        else
            echo ""
        fi
    }

    # 构建时间显示
    position=$(format_time_from_sec "$position_sec")
    duration=$(format_time_from_us "$length_us")
    if [ -n "$duration" ]; then
        time_display="$position / $duration"
    else
        time_display="$position"
    fi

    # 输出：歌手、专辑、歌名、时间（4 行）
    echo "${artist:-Unknown Artist}"
    echo "${album:-Unknown Album}"
    echo "${title:-Unknown Title}"
    echo "$time_display"
else
    # 无播放时也输出 4 行，防止 Conky sed 错位
    echo "No Music Played"
    echo ""
    echo ""
    echo ""
fi