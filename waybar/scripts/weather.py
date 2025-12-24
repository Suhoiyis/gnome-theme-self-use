#!/usr/bin/env python3
import json
import sys
from datetime import datetime

import requests

# ================= 配置区域 =================
# 建议填入拼音 "Qu,City" 或经纬度
LOCATION = "成华,成都"
# ===========================================

# --- 天气代码 -> 中文描述 映射表 ---
# 这是一个基于 WMO 4677 标准的完整汉化表
WMO_TRANSLATION = {
    "113": "晴",
    "116": "多云",
    "119": "阴",
    "122": "阴",
    "143": "薄雾",
    "176": "局部小雨",
    "179": "小雪",
    "182": "小雨夹雪",
    "185": "冻雨",
    "200": "雷阵雨",
    "227": "吹雪",
    "230": "暴风雪",
    "248": "雾",
    "260": "冻雾",
    "263": "小雨",
    "266": "小雨",
    "281": "冻雨",
    "284": "冻雨",
    "293": "局部小雨",
    "296": "小雨",
    "299": "小雨",
    "302": "中雨",
    "305": "中雨",
    "308": "大雨",
    "311": "冻雨",
    "314": "小雨",
    "317": "小雨夹雪",
    "320": "小雨夹雪",
    "323": "小雪",
    "326": "小雪",
    "329": "中雪",
    "332": "中雪",
    "335": "大雪",
    "338": "大雪",
    "350": "冰雹",
    "353": "小雨",
    "356": "中雨",
    "359": "大雨",
    "362": "雨夹雪",
    "365": "雨夹雪",
    "368": "小雪",
    "371": "中雪",
    "374": "小冰雹",
    "377": "冰雹",
    "386": "雷阵雨",
    "389": "雷暴",
    "392": "雷雪",
    "395": "大雪",
}

# --- 天气代码 -> 图标 映射表 ---
WEATHER_ICONS = {
    "113": "☀️ ",
    "116": "⛅ ",
    "119": "☁️ ",
    "122": "☁️ ",
    "143": "🌫 ",
    "176": "🌦 ",
    "179": "🌧 ",
    "182": "🌧 ",
    "185": "🌧 ",
    "200": "⛈ ",
    "227": "🌨 ",
    "230": "❄️ ",
    "248": "🌫 ",
    "260": "🌫 ",
    "263": "🌦 ",
    "266": "🌦 ",
    "281": "🌧 ",
    "284": "🌧 ",
    "293": " ",
    "296": "🌧 ",
    "299": "🌧 ",
    "302": "🌧 ",
    "305": "🌧 ",
    "308": "🌧 ",
    "311": "🌧 ",
    "314": "🌧 ",
    "317": "🌧 ",
    "320": "🌨 ",
    "323": "🌨 ",
    "326": "🌨 ",
    "329": "❄️ ",
    "332": "❄️ ",
    "335": "❄️ ",
    "338": "❄️ ",
    "350": "🌧 ",
    "353": "🌦 ",
    "356": "🌧 ",
    "359": "🌧 ",
    "362": "🌧 ",
    "365": "🌧 ",
    "368": "🌨 ",
    "371": "🌨 ",
    "374": "🌧 ",
    "377": "🌧 ",
    "386": "⛈ ",
    "389": "⛈ ",
    "392": "⛈ ",
    "395": "❄️ ",
}


def get_desc(code):
    """根据天气代码获取中文描述，如果没找到则返回未知"""
    return WMO_TRANSLATION.get(code, "未知")


def parse_time(time_str):
    return time_str.zfill(4)[:2] + ":00"


try:
    url = f"https://wttr.in/{LOCATION}?format=j1"

    # 伪装成 curl 或者 浏览器，防止被服务器重置连接
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    }
    # 设置超时时间，防止 Waybar 卡死
    res = requests.get(url, headers=headers, timeout=10)

    data = res.json()

    # --- 1. 状态栏显示 (Bar) ---
    current = data["current_condition"][0]
    temp_C = current["temp_C"]
    code = current["weatherCode"]

    icon = WEATHER_ICONS.get(code, "")
    # 状态栏现在只显示 图标 + 温度 (保持简洁)
    text = f"{icon}{temp_C}°C"

    # --- 2. 悬浮窗显示 (Tooltip) ---
    tooltip_lines = []

    # 标题
    area = data["nearest_area"][0]["areaName"][0]["value"]
    feels_like = current["FeelsLikeC"]
    current_desc = get_desc(code)
    tooltip_lines.append(f"<b>📍 {area}</b>: {current_desc}")

    # === 未来趋势 (Next 9 Hours) ===
    tooltip_lines.append("<b>🕐 未来趋势:</b>")

    current_hour = datetime.now().hour
    today_hourly = data["weather"][0]["hourly"]
    tomorrow_hourly = data["weather"][1]["hourly"]

    timeline = []
    for h in today_hourly:
        timeline.append((int(h["time"]) // 100, h, False))
    for h in tomorrow_hourly:
        timeline.append((int(h["time"]) // 100, h, True))

    count = 0
    for hour_int, h, is_tomorrow in timeline:
        if count >= 3:
            break

        if is_tomorrow or (hour_int > current_hour):
            time_str = parse_time(h["time"])
            temp = h["tempC"]
            # 这里调用汉化函数
            desc = get_desc(h["weatherCode"])

            day_label = "(+1)" if is_tomorrow else ""

            # 使用中文全角空格或者制表符对齐
            tooltip_lines.append(f"<tt>{time_str} | {temp}°C | {desc}</tt>")
            count += 1

    # tooltip_lines.append("")

    # === 每日概览 ===
    tooltip_lines.append("<b>🗓️ 每日概览:</b>")
    # 中文星期映射
    WEEK_MAP = {
        "Mon": "周一",
        "Tue": "周二",
        "Wed": "周三",
        "Thu": "周四",
        "Fri": "周五",
        "Sat": "周六",
        "Sun": "周日",
    }

    for i, day in enumerate(data["weather"]):
        if i == 0:
            continue
        date_obj = datetime.strptime(day["date"], "%Y-%m-%d")

        # 获取英文星期并转中文
        en_day = date_obj.strftime("%a")
        cn_day = WEEK_MAP.get(en_day, en_day)

        maxtemp = day["maxtempC"]
        mintemp = day["mintempC"]

        # 获取中午12点的天气代码进行汉化
        noon_code = day["hourly"][4]["weatherCode"]
        desc = get_desc(noon_code)

        tooltip_lines.append(f"<b>{cn_day}</b>: {mintemp}~{maxtemp}°C {desc}")

    print(
        json.dumps(
            {"text": text, "tooltip": "\n".join(tooltip_lines), "class": "weather"}
        )
    )

except Exception as e:
    print(json.dumps({"text": "Err", "tooltip": str(e)}))
