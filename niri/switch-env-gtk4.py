#!/usr/bin/env python3

"""
Niri 环境切换工具 - GTK4 版本
最现代美观的图形界面
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, GLib, Gio
import subprocess
import shutil
from pathlib import Path
from datetime import datetime

class EnvironmentCard(Gtk.Box):
    """环境选择卡片"""
    def __init__(self, title, description, icon, **kwargs):
        super().__init__(**kwargs)
        self.set_orientation(Gtk.Orientation.VERTICAL)
        self.set_spacing(8)
        self.add_css_class('card')
        self.add_css_class('environment-card')

        # 图标
        icon_widget = Gtk.Label(label=icon)
        icon_widget.add_css_class('environment-icon')
        self.append(icon_widget)

        # 标题
        title_label = Gtk.Label(label=title)
        title_label.add_css_class('title-3')
        title_label.set_wrap(True)
        self.append(title_label)

        # 描述
        desc_label = Gtk.Label(label=description)
        desc_label.add_css_class('dim-label')
        desc_label.add_css_class('caption')
        desc_label.set_wrap(True)
        desc_label.set_justify(Gtk.Justification.CENTER)
        self.append(desc_label)

class NiriSwitcher(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.config_base = Path.home() / ".config"
        self.niri_config = self.config_base / "niri"

        # 环境配置
        self.environments = [
            {
                "name": "Linux-wallpaper + Waybar",
                "icon": "🖼️",
                "desc": "使用 Linux wallpaper engine\n管理动态壁纸，Waybar 状态栏",
                "path": "niri_linux-wallpaper+waybar"
            },
            {
                "name": "Noctalia Shell",
                "icon": "🎨",
                "desc": "完整的 Noctalia 桌面环境\n统一管理壁纸、状态栏和小部件",
                "path": "niri_noctalia"
            },
            {
                "name": "Noctalia + Wallpaper",
                "icon": "🎭",
                "desc": "Noctalia 管理状态栏\nLinux wallpaper engine 管理动态壁纸",
                "path": "niri_noctalia+wallpaper"
            },
            {
                "name": "Swww + Waybar",
                "icon": "🌈",
                "desc": "使用 Swww 切换壁纸\nWaybar 作为状态栏",
                "path": "niri_swww+waybar"
            }
        ]

        self.selected_env = None
        self.setup_ui()

    def setup_ui(self):
        """设置界面"""
        self.set_default_size(800, 600)
        self.set_title("Niri 环境切换")

        # 主容器
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        # Header Bar
        header = Adw.HeaderBar()
        main_box.append(header)

        # 内容容器
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        content.set_margin_top(20)
        content.set_margin_bottom(20)
        content.set_margin_start(20)
        content.set_margin_end(20)
        content.set_spacing(20)

        # 标题和副标题
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        title_box.set_halign(Gtk.Align.CENTER)

        title = Gtk.Label(label="Niri 桌面环境切换")
        title.add_css_class('title-1')
        title_box.append(title)

        subtitle = Gtk.Label(label="选择你想要使用的桌面环境配置")
        subtitle.add_css_class('dim-label')
        title_box.append(subtitle)

        content.append(title_box)

        # 环境卡片网格
        grid = Gtk.Grid()
        grid.set_row_spacing(16)
        grid.set_column_spacing(16)
        grid.set_halign(Gtk.Align.CENTER)

        self.buttons = []

        for idx, env in enumerate(self.environments):
            # 创建按钮容器
            button = Gtk.Button()
            button.set_size_request(350, 150)
            button.connect('clicked', self.on_env_selected, idx)

            # 创建卡片
            card = EnvironmentCard(
                title=env["name"],
                description=env["desc"],
                icon=env["icon"]
            )
            button.set_child(card)

            # 添加到网格 (2x2)
            row = idx // 2
            col = idx % 2
            grid.attach(button, col, row, 1, 1)

            self.buttons.append(button)

        content.append(grid)

        # 提示信息
        info_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        info_box.set_halign(Gtk.Align.CENTER)
        info_box.add_css_class('card')
        info_box.set_margin_top(10)

        info_icon = Gtk.Label(label="ℹ️")
        info_box.append(info_icon)

        info_label = Gtk.Label(label="切换环境后将自动注销，重新登录后生效")
        info_label.add_css_class('caption')
        info_label.add_css_class('dim-label')
        info_box.append(info_label)

        content.append(info_box)

        main_box.append(content)
        self.set_content(main_box)

        # 加载 CSS
        self.load_css()

    def load_css(self):
        """加载自定义样式"""
        css_provider = Gtk.CssProvider()
        css = b"""
        .environment-card {
            padding: 20px;
            margin: 4px;
        }

        .environment-icon {
            font-size: 48px;
        }

        button:hover .environment-card {
            background-color: alpha(@accent_color, 0.1);
        }

        .card {
            padding: 12px;
            border-radius: 8px;
        }
        """
        css_provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_display(
            self.get_display(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def on_env_selected(self, button, idx):
        """选择环境"""
        self.selected_env = self.environments[idx]
        self.show_confirm_dialog()

    def show_confirm_dialog(self):
        """显示确认对话框"""
        dialog = Adw.MessageDialog.new(self)
        dialog.set_heading("确认切换环境")
        dialog.set_body(
            f"确认切换到以下环境?\n\n"
            f"{self.selected_env['icon']} {self.selected_env['name']}\n\n"
            f"{self.selected_env['desc']}\n\n"
            f"⚠️  切换后将自动注销"
        )

        dialog.add_response("cancel", "取消")
        dialog.add_response("switch", "切换")
        dialog.set_response_appearance("switch", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("switch")
        dialog.set_close_response("cancel")

        dialog.connect('response', self.on_confirm_response)
        dialog.present()

    def on_confirm_response(self, dialog, response):
        """确认对话框响应"""
        if response == "switch":
            self.switch_environment()

    def switch_environment(self):
        """切换环境"""
        env_path = self.config_base / self.selected_env["path"]

        # 检查路径
        if not env_path.exists():
            self.show_error(f"环境目录不存在:\n{env_path}")
            return

        try:
            # 备份
            backup_dir = self.niri_config / f".backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            backup_dir.mkdir(parents=True, exist_ok=True)

            for item in self.niri_config.glob("*"):
                if item.name.startswith(".backup"):
                    continue
                if item.is_dir():
                    shutil.copytree(item, backup_dir / item.name, dirs_exist_ok=True)
                else:
                    shutil.copy2(item, backup_dir / item.name)

            # 只保留最近 5 个备份，删除更旧的
            backups = sorted(
                [p for p in self.niri_config.glob(".backup_*") if p.is_dir()],
                key=lambda p: p.name,
                reverse=True,
            )
            for old in backups[5:]:
                shutil.rmtree(old, ignore_errors=True)

            # 复制新配置
            for item in env_path.glob("*"):
                dest = self.niri_config / item.name
                if dest.exists():
                    if dest.is_dir():
                        shutil.rmtree(dest)
                    else:
                        dest.unlink()

                if item.is_dir():
                    shutil.copytree(item, dest)
                else:
                    shutil.copy2(item, dest)

            # 清理旧配置（保留备份、Python 应用及虚拟环境），再复制新配置
            self.clean_current_config()

            # 根据环境修改 Noctalia 壁纸设置
            self.configure_noctalia_wallpaper()

            # 显示成功并注销
            self.show_success()

        except Exception as e:
            self.show_error(f"切换失败:\n{str(e)}")

    def clean_current_config(self):
        """删除现有 niri 配置（kdl 和 scripts），保留必要文件/目录"""
        keep_files = {"switch-env-gtk4.py"}
        keep_prefixes = (".backup_", ".venv", "venv")  # 备份与可能的 Python 虚拟环境
        keep_dirs = {"__pycache__"}

        for item in self.niri_config.iterdir():
            name = item.name

            # 保留备份、虚拟环境、应用本身
            if name.startswith(keep_prefixes) or name in keep_files or name in keep_dirs:
                continue

            # 删除其余 kdl、scripts 等，确保不会污染环境
            if item.is_dir():
                shutil.rmtree(item, ignore_errors=True)
            else:
                try:
                    item.unlink()
                except FileNotFoundError:
                    pass

    def configure_noctalia_wallpaper(self):
        """根据环境配置 Noctalia 的壁纸设置"""
        import json

        noctalia_config = Path.home() / ".config" / "noctalia" / "settings.json"

        if not noctalia_config.exists():
            return  # Noctalia 未安装，忽略

        try:
            with open(noctalia_config, 'r', encoding='utf-8') as f:
                data = json.load(f)

            # 根据环境确定是否启用 Noctalia 壁纸管理
            env_name = self.selected_env["path"]

            # noctalia 环境启用壁纸，其他环境禁用
            if env_name == "niri_noctalia":
                data["wallpaper"]["enabled"] = True
            else:
                data["wallpaper"]["enabled"] = False

            # 写回配置
            with open(noctalia_config, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

        except Exception as e:
            # 配置修改失败不阻止切换，只记录
            print(f"警告: Noctalia 壁纸配置修改失败: {e}")

    def show_success(self):
        """显示成功消息，带倒计时"""
        self.countdown = 3  # 倒计时秒数

        dialog = Adw.MessageDialog.new(self)
        dialog.set_heading("✅ 切换完成")

        # 初始显示
        self.success_dialog = dialog
        self.update_countdown_message()

        dialog.add_response("ok", "立即重启")
        dialog.set_default_response("ok")
        dialog.connect('response', lambda d, r: self.logout())

        dialog.present()

        # 每秒更新倒计时
        GLib.timeout_add_seconds(1, self.update_countdown)

    def update_countdown_message(self):
        """更新倒计时消息"""
        if hasattr(self, 'success_dialog'):
            self.success_dialog.set_body(f"环境切换成功!\n\n将在 {self.countdown} 秒后自动重启...")

    def update_countdown(self):
        """每秒更新倒计时"""
        self.countdown -= 1
        self.update_countdown_message()

        if self.countdown <= 0:
            self.logout()
            return False  # 停止定时器

        return True  # 继续定时器

    def show_error(self, message):
        """显示错误消息"""
        dialog = Adw.MessageDialog.new(self)
        dialog.set_heading("错误")
        dialog.set_body(message)
        dialog.add_response("ok", "确定")
        dialog.present()

    def logout(self):
        """改为重启：更彻底且避免 GDM 登录循环问题"""
        try:
            import time
            # 尝试优雅退出 Niri，避免屏幕闪烁
            try:
                subprocess.run(["niri", "msg", "quit"], timeout=2)
            except Exception:
                subprocess.run(["pkill", "-x", "niri"], timeout=2)
            time.sleep(0.5)

            # 触发系统重启（优先 loginctl，其次 systemctl，最后 shutdown）
            for cmd in (["loginctl", "reboot"], ["systemctl", "reboot"], ["shutdown", "-r", "now"]):
                try:
                    subprocess.run(cmd, check=True)
                    break
                except Exception:
                    continue

            return False
        except subprocess.TimeoutExpired:
            os._exit(1)
        except Exception as e:
            print(f"Reboot error: {e}")
            os._exit(1)

class NiriSwitcherApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id='com.niri.switcher')
        self.connect('activate', self.on_activate)

    def on_activate(self, app):
        win = NiriSwitcher(application=app)
        win.present()

if __name__ == "__main__":
    app = NiriSwitcherApp()
    app.run(None)
