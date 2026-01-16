位置与启动

主程序：/home/yua/.config/niri/switch-env-gtk4.py
启动器：/home/yua/.local/share/applications/niri-switch-env.desktop
启动方式：在启动器里搜索 “Niri 环境切换”，或终端运行 python3 ~/.config/niri/switch-env-gtk4.py
功能

2x2 卡片式界面，列出四个环境：
niri_ linux-wallpaper+waybar
niri_ noctalia
niri_noctalia+wallpaper
niri_swww+waybar
选择后复制对应配置到 ~/.config/niri/ 并自动注销
3 秒动态倒计时，按钮“立即注销”可手动触发
注销逻辑：优先 terminate 当前 session（kill-session → terminate-session），找不到 session 时回退 kill-user/terminate-user
依赖

GTK4 + libadwaita 运行时（python-gobject）
loginctl (systemd)
Python 3.10+（已在本机可用）
常用修改点

窗口规则：在 ~/.config/niri/rule.kdl 里已加 match app-id="com.niri.switcher"，默认浮动，900×700。
倒计时时长：self.countdown = 3（在 show_success 里）改数字即可。
终端/图标：桌面文件里 Icon=preferences-system 可改成别的系统图标名或自定义路径。
故障排查

“环境目录不存在”：确认四个环境目录名称与脚本内 self.environments 的 path 一致（当前已修正含空格的前缀）。
注销后提示有其他用户登录：可能是残留 session。脚本已切换为 session 优先终止，仍有问题可检查 linger：loginctl show-user $USER -p Linger，必要时 sudo loginctl disable-linger $USER。