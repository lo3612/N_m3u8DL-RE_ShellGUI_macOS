# N_m3u8DL-RE_ShellGUI_macOS

![License](https://img.shields.io/github/license/lo3612/N_m3u8DL-RE_ShellGUI_macOS)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Language](https://img.shields.io/badge/language-Shell%20Script-blue)
![GitHub stars](https://img.shields.io/github/stars/lo3612/N_m3u8DL-RE_ShellGUI_macOS)

基于 [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI) 的 macOS 优化版本，提供更便捷的 m3u8 视频下载和管理功能。

## ✨ 功能特性

- ✅ 单个/批量 m3u8 视频下载
- ✅ 直播流录制（支持定时停止）
- ✅ 自动更新核心组件（N_m3u8DL-RE 和 FFmpeg）
- ✅ 高级功能：字幕提取、音视频分离等
- ✅ 图形化界面操作
- ✅ 支持自定义下载目录和缓存设置

## 🚀 快速开始

### 前置要求

- macOS 系统
- Git（可选，用于克隆仓库）
- 终端应用

### 安装步骤

```bash
# 克隆仓库
git clone https://github.com/lo3612/N_m3u8DL-RE_ShellGUI_macOS.git
cd N_m3u8DL-RE_ShellGUI_macOS

# 设置执行权限
chmod +x *.sh

# 安装依赖（自动下载N_m3u8DL-RE和FFmpeg）
./install.sh

# 启动程序
./start.sh
```

## 📂 文件结构

```
.
├── install.sh          # 一键安装脚本
├── start.sh            # 启动脚本
├── auto_update.sh      # 自动更新脚本
├── m3u8DL_enhanced.sh  # 主程序界面
├── advanced.sh         # 高级功能脚本
├── common.sh           # 公共函数库
├── config.conf         # 配置文件
├── LICENSE             # 许可证文件
└── README.md           # 说明文档
```

## ⚙️ 配置说明

编辑 `config.conf` 可自定义以下设置：

```ini
# 下载目录（默认：./downloads/）
download_dir=./downloads/

# 临时文件目录（默认：./temp/）
temp_dir=./temp/

# FFmpeg路径（默认自动下载）
ffmpeg_path=./ffmpeg
```

## ❓ 常见问题

### 安装问题
- **权限被拒绝**：运行 `chmod +x *.sh` 添加执行权限
- **依赖安装失败**：检查网络连接后重试 `./install.sh`

### 使用问题
- **下载失败**：
  - 确认m3u8链接有效
  - 检查网络连接
  - 尝试更换DNS（如8.8.8.8）

- **视频无法播放**：
  - 确保FFmpeg安装正确
  - 尝试使用高级功能中的修复选项

## 🤝 贡献指南

欢迎通过 Issue 或 Pull Request 贡献代码！提交前请确保：

1. 代码符合Shell脚本规范
2. 新增功能包含相应测试
3. 更新相关文档（包括本README）

## 📄 许可证

本项目采用 [MIT License](LICENSE)。

核心组件许可：
- [N_m3u8DL-RE](https://github.com/nilaoda/N_m3u8DL-RE) - MIT License
- [FFmpeg](https://ffmpeg.org) - LGPL v2.1+

## 🙏 致谢

- [N_m3u8DL-RE_SimpleBatGUI](https://github.com/LennoC/N_m3u8DL-RE_SimpleBatGUI)
- [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI) 
- [N_m3u8DL-RE](https://github.com/nilaoda/N_m3u8DL-RE)
- [FFmpeg](https://ffmpeg.org)