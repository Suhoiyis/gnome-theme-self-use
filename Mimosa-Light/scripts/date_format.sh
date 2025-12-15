#!/bin/bash
# date_format.sh - 输出 Mon    Nov.24th 格式

# 设置临时 locale 为英语
export LANG=en_US.UTF-8

# 获取当前日期
day=$(date +%d)
month=$(date +%m)
weekday=$(date +%a)  # 现在会输出 Sun/Mon/Tue...

# 月份缩写数组
months=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
month_abbr=${months[$((month-1))]}
month_abbr="${month_abbr}."

# 序数后缀
case $day in
    1|21|31) suffix="st" ;;
    2|22) suffix="nd" ;;
    3|23) suffix="rd" ;;
    *) suffix="th" ;;
esac

# 输出：Mon   Nov.24th
printf "%s   %s%d%s\n" "$weekday" "$month_abbr" "$day" "$suffix"
