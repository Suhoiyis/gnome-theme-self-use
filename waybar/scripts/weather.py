#!/usr/bin/env python3
import json
import sys
from datetime import datetime

import requests

# ================= 配置区域 =================
LOCATION = "成华，成都"
# ===========================================

WEATHER_CODES = {
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


def parse_time(time_str):
    # 将 "300" 转为 "03:00", "0" 转为 "00:00"
    return time_str.zfill(4)[:2] + ":00"


try:
    # 获取数据
    url = f"https://wttr.in/{LOCATION}?format=j1"
    res = requests.get(url)
    data = res.json()

    # --- 1. 状态栏显示 (Bar) ---
    current = data["current_condition"][0]
    temp_C = current["temp_C"]
    weather_code = current["weatherCode"]
    icon = WEATHER_CODES.get(weather_code, "Unknown")
    text = f"{icon}{temp_C}°C"

    # --- 2. 悬浮窗显示 (Tooltip) ---
    tooltip_lines = []

    # 标题：地点 + 体感
    area = data["nearest_area"][0]["areaName"][0]["value"]
    feels_like = current["FeelsLikeC"]
    tooltip_lines.append(f"<b>📍 {area}</b> (Feels {feels_like}°)\n")

    # === 核心逻辑：跨天预测 ===
    tooltip_lines.append("<b>🕐 未来趋势 :</b>")

    # 获取当前小时 (0-23)
    current_hour = datetime.now().hour

    # 提取今天和明天的所有小时数据
    today_hourly = data["weather"][0]["hourly"]
    tomorrow_hourly = data["weather"][1]["hourly"]

    # 将它们打平合并成一个大列表，并标记来源
    # 格式: (小时数字, 数据对象, 是否是明天)
    timeline = []

    for h in today_hourly:
        hour_int = int(h["time"]) // 100
        timeline.append((hour_int, h, False))  # False = 今天

    for h in tomorrow_hourly:
        hour_int = int(h["time"]) // 100
        timeline.append((hour_int, h, True))  # True = 明天

    # 寻找未来 3 个节点
    future_slots = []
    found_count = 0

    for hour_int, weather_obj, is_tomorrow in timeline:
        # 如果已经找够了3个，停止
        if found_count >= 3:
            break

        # 逻辑：
        # 1. 如果是明天的 slot，无条件加入 (因为肯定比今天现在晚)
        # 2. 如果是今天的 slot，必须晚于当前时间
        if is_tomorrow or (hour_int > current_hour):
            future_slots.append((hour_int, weather_obj, is_tomorrow))
            found_count += 1

    # 渲染这 3 个数据
    for hour_int, h, is_tomorrow in future_slots:
        time_str = parse_time(h["time"])
        temp = h["tempC"]
        desc = h["weatherDesc"][0]["value"]
        wind = h["windspeedKmph"]

        # 如果是明天的时间，加上 (+1) 标记，或者特殊显示
        day_label = "(+1)" if is_tomorrow else ""

        # 格式化输出
        # 例如: 21:00 | 18°C | Rain
        tooltip_lines.append(f"<tt>{time_str} | {temp}°C | {desc}</tt>")

    tooltip_lines.append("")  # 空行

    # --- 3. 未来几天的概览 ---
    tooltip_lines.append("<b>🗓️ 每日概览:</b>")
    for i, day in enumerate(data["weather"]):
        if i == 0:
            continue
        date_obj = datetime.strptime(day["date"], "%Y-%m-%d")
        day_name = date_obj.strftime("%a")
        maxtemp = day["maxtempC"]
        mintemp = day["mintempC"]
        desc = day["hourly"][4]["weatherDesc"][0]["value"]
        tooltip_lines.append(f"<b>{day_name}</b>: {mintemp}°~{maxtemp}°C {desc}")

    print(
        json.dumps(
            {"text": text, "tooltip": "\n".join(tooltip_lines), "class": "weather"}
        )
    )

except Exception as e:
    print(json.dumps({"text": "Err", "tooltip": str(e)}))
