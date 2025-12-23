#!/usr/bin/env python3
import json
import sys
import urllib.parse
import urllib.request
import webbrowser

# ================= 配置区域 =================
API_KEY = "916e8ab926a8a3b8f9929bf03965e7db"
CITY = "Chengdu"
LANG = "zh_cn"
# ===========================================


def get_icon(icon_code):
    icon_map = {
        "01d": "",
        "01n": "",
        "02d": "",
        "02n": "",
        "03d": "",
        "03n": "",
        "04d": "",
        "04n": "",
        "09d": "",
        "09n": "",
        "10d": "",
        "10n": "",
        "11d": "",
        "11n": "",
        "13d": "",
        "13n": "",
        "50d": "",
        "50n": "",
    }
    return icon_map.get(icon_code, "")


def get_wind_direction(deg):
    directions = [
        "北风",
        "北偏东",
        "东北风",
        "东偏北",
        "东风",
        "东偏南",
        "东南风",
        "南偏东",
        "南风",
        "南偏西",
        "西南风",
        "西偏南",
        "西风",
        "西偏北",
        "西北风",
        "北偏西",
    ]
    idx = round(deg / 22.5) % 16
    return directions[idx]


def fetch_weather():
    if API_KEY == "你的_API_KEY_粘贴在这里":
        raise Exception("请填写 API Key")

    # 构造请求 URL
    url = f"https://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric&lang={LANG}"

    # 发送请求
    # 使用 ProxyHandler({}) 强制不走代理，确保速度和定位准确（如果用自动定位的话）
    proxy_handler = urllib.request.ProxyHandler({})
    opener = urllib.request.build_opener(proxy_handler)

    with opener.open(url) as response:
        return json.loads(response.read().decode())


def main():
    try:
        # 1. 如果命令行参数包含 "open"，则执行打开网页操作
        if len(sys.argv) > 1 and sys.argv[1] == "open":
            # 我们先请求一次数据以获取准确的 City ID
            # 这样能确保跳转到准确的城市页面 (比如 Chengdu, CN 而不是 Chengdu, US)
            try:
                data = fetch_weather()
                city_id = data["id"]
                target_url = f"https://openweathermap.org/city/{city_id}"
            except:
                # 如果获取失败（比如没网），则回退到搜索页面
                target_url = f"https://openweathermap.org/find?q={CITY}"

            webbrowser.open(target_url)
            sys.exit(0)

        # 2. 正常模式：获取数据并输出 JSON
        data = fetch_weather()

        # 解析数据
        temp = round(data["main"]["temp"])
        feels_like = round(data["main"]["feels_like"])
        humidity = data["main"]["humidity"]
        description = data["weather"][0]["description"]
        icon_code = data["weather"][0]["icon"]
        city_name = data["name"]
        country = data["sys"]["country"]
        wind_speed_kmh = round(data["wind"]["speed"] * 3.6, 1)
        wind_dir_str = get_wind_direction(data.get("wind", {}).get("deg", 0))
        icon = get_icon(icon_code)

        # 构造 Tooltip
        tooltip = (
            f"<b>{city_name}, {country}</b>\n"
            f"----------------\n"
            f"描述: {description}\n"
            f"体感: {feels_like}°C\n"
            f"湿度: {humidity}%\n"
            f"风向: {wind_dir_str} ({wind_speed_kmh}km/h)"
        )

        print(
            json.dumps(
                {"text": f"{icon} {temp}°C", "tooltip": tooltip, "class": "weather"}
            )
        )

    except Exception as e:
        # 仅在非打开模式下输出错误 JSON
        if len(sys.argv) <= 1:
            print(
                json.dumps(
                    {"text": " N/A", "tooltip": f"错误: {str(e)}", "class": "weather"}
                )
            )


if __name__ == "__main__":
    main()
