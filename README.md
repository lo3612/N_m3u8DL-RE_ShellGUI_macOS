# N_m3u8DL-RE_ShellGUI_macOS

## 注意！
本质上只是在 [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI) 大佬的脚本基础上对 macOS 进行了优化，因此并没有太大的改变。

默认下载路径和缓存路径以及 ffmpeg 路径可以在脚本文件的**目录设置**注释一栏进行修改。默认路径在 `Download/m3u8DL` 文件夹下，ffmpeg 为 brew 的默认路径。

## 使用说明
1. 下载最新的 [N_m3u8DL-RE](https://github.com/nilaoda/N_m3u8DL-RE)（因为它是运行本脚本所必须的核心程序），将它放置在本脚本所在根目录下。

2. 使用 brew 安装 ffmpeg：
    ```sh
    brew install ffmpeg
    ```

3. 给脚本添加执行权限：
    ```sh
    chmod +x m3u8DL.sh
    chmod +x N_m3u8DL-RE
    ```

4. 准备工作完成后，运行脚本：
    ```sh
    ./m3u8DL.sh
    ```

## 补充说明
批量下载文件的格式为 `名称$链接`，多个资源可以多行粘贴，例如：
> 第01集$https://v.gsuus.com/play/oeE2D4Ka/index.m3u8  
> 第02集$https://v.gsuus.com/play/7axBQXnd/index.m3u8  
> 第03集$https://v.gsuus.com/play/0dN2P4Kd/index.m3u8  

## 引用
- [N_m3u8DL-RE_SimpleBatGUI](https://github.com/LennoC/N_m3u8DL-RE_SimpleBatGUI)  
- [N_m3u8DL-RE_ShellGUI](https://github.com/RoadIsLong/N_m3u8DL-RE_ShellGUI)  
- [N_m3u8DL-RE](https://github.com/nilaoda/N_m3u8DL-RE)
