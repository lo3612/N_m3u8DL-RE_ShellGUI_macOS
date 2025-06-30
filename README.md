# N_m3u8DL-RE_ShellGUI_macOS

基于 [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI) 的 macOS 优化版本。

## 特性

- 一键安装 N_m3u8DL-RE 和 ffmpeg
- 自动更新主程序和 ffmpeg
- 简洁菜单界面，操作简单
- 支持单个/批量下载、直播录制
- 配置文件自动生成

## 快速开始

```bash
# 下载项目
git clone https://github.com/lo3612/N_m3u8DL-RE_ShellGUI_macOS.git
cd N_m3u8DL-RE_ShellGUI_macOS

# 安装
./install.sh

# 启动
./start.sh
```

## 文件说明

- `install.sh` - 一键安装脚本
- `start.sh` - 快速启动脚本
- `auto_update.sh` - 自动更新脚本
- `m3u8DL_enhanced.sh` - 主程序界面
- `advanced.sh` - 高级功能脚本
- `common.sh` - 公共函数库
- `config.conf` - 配置文件

## 功能菜单

1. **单个视频下载** - 输入链接和文件名下载
2. **批量下载** - 支持批量链接文件
3. **直播录制** - 支持定时自动停止
4. **高级功能** - 字幕提取、音视频分离等
5. **设置** - 修改下载路径、缓存路径等
6. **自动更新** - 更新主程序和 ffmpeg

## 批量下载格式

每行一个链接：
```
https://example.com/video1.m3u8
https://example.com/video2.m3u8
```

或带名称格式：
```
第01集$https://example.com/video1.m3u8
第02集$https://example.com/video2.m3u8
```

## 配置

默认配置可在 `config.conf` 中修改：
- 下载目录：`downloads/`
- 缓存目录：`temp/`
- ffmpeg 路径：自动下载到脚本目录

## 常见问题

- **程序无法启动** → 运行 `./install.sh`
- **下载失败** → 检查网络和链接
- **权限问题** → `chmod +x *.sh`
- **更新失败** → 检查网络或手动运行 `./auto_update.sh`

## 致谢

- [N_m3u8DL-RE_SimpleBatGUI](https://github.com/LennoC/N_m3u8DL-RE_SimpleBatGUI)
- [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI)
- [N_m3u8DL-RE](https://github.com/nilaoda/N_m3u8DL-RE)
