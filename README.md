# N_m3u8DL-RE_ShellGUI_macOS

## 注意！
本项目本质上是在 [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI) 大佬的脚本基础上针对 macOS 进行了优化，主要提升了自动化和易用性，核心功能未做大幅改变。

**默认下载路径、缓存路径、ffmpeg 路径等可在脚本文件的"默认设置"注释一栏修改。**

---

## 文件结构
N_m3u8DL-RE_ShellGUI_macOS/
├── start.sh # 快速启动脚本
├── install.sh # 一键安装脚本
├── auto_update.sh # 自动更新脚本
├── m3u8DL_enhanced.sh # 主程序
├── advanced.sh # 高级功能
└── README.md # 说明文档

---

## 主要特性

- 一键自动安装 N_m3u8DL-RE 和 ffmpeg，无需手动下载
- 支持自动更新主程序和 ffmpeg
- - 支持单个/批量下载、直播录制、高级功能
- 配置文件自动生成，参数可菜单化修改

---

## 使用说明

### 1. 下载项目

```sh
git clone https://github.com/lo3612/N_m3u8DL-RE_ShellGUI_macOS.git
cd N_m3u8DL-RE_ShellGUI_macOS
```

### 2. 一键安装

```sh
./install.sh
```
> 自动下载 N_m3u8DL-RE 和 ffmpeg，自动设置权限。

### 3. 启动主程序

```sh
./start.sh
```
> 检查环境并进入主菜单。

也可直接运行主程序：

```sh
./m3u8DL_enhanced.sh
```

---

## 常用功能

- **单个视频下载**：输入链接和文件名即可下载
- **批量下载**：支持批量链接文件（每行一个链接）
- **直播录制**：支持定时自动停止
- **高级功能**：字幕提取、音视频分离、加密解密、分片下载等

---

## 批量下载文件格式

每行一个链接，支持简单格式：
```
https://example.com/video1.m3u8
https://example.com/video2.m3u8
```
也兼容"名称$链接"格式（会自动处理）：
```
第01集$https://v.gsuus.com/play/oeE2D4Ka/index.m3u8
第02集$https://v.gsuus.com/play/7axBQXnd/index.m3u8
```

---

## 配置说明

- 默认下载目录：`downloads/`
- 默认缓存目录：`temp/`
- ffmpeg 路径：自动下载到脚本目录
- 其他参数可在菜单"设置"中修改，或直接编辑 `config.conf`

---

## 常见问题

- **程序无法启动/找不到主程序**  
  运行 `./install.sh` 自动安装
- **下载失败**  
  检查网络和链接有效性
- **权限问题**  
  赋予脚本执行权限：`chmod +x *.sh`
- **更新失败**  
  检查网络，或手动运行 `./auto_update.sh`

---

## 致谢与引用

- [N_m3u8DL-RE_SimpleBatGUI](https://github.com/LennoC/N_m3u8DL-RE_SimpleBatGUI)
- [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI)
- [N_m3u8DL-RE](https://github.com/nilaoda/N_m3u8DL-RE)

---

## 许可证

本项目基于 N_m3u8DL-RE 及相关 ShellGUI 项目，遵循原项目许可证。 
