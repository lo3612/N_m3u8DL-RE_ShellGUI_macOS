#!/bin/bash

# N_m3u8DL-RE 一键安装脚本
# 版本: 2.1.0
# 日期: 2025-6-30

# 引入公共函数库
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo "========================================"
echo "    N_m3u8DL-RE 一键安装"
echo "========================================"
echo ""

echo "开始安装N_m3u8DL-RE..."

# 下载N_m3u8DL-RE
if ! download_n_m3u8dl_re "install" "false"; then
    echo -e "${RED}N_m3u8DL-RE 安装失败${RESET}"
    exit 1
fi

# 下载ffmpeg
if ! download_ffmpeg "install" "false"; then
    echo -e "${RED}ffmpeg 安装失败${RESET}"
    exit 1
fi

# 设置权限
set_permissions
auto_set_exec_permissions

echo -e "${GREEN}安装完成!${RESET}"
echo ""

# 询问是否启动程序
read -p "是否立即启动程序? (y/n): " start_program
if [[ "$start_program" == "y" || "$start_program" == "Y" ]]; then
    echo ""
    echo "启动 N_m3u8DL-RE..."
    echo ""
    ./m3u8DL_enhanced.sh
else
    echo "您可以稍后运行 ./start.sh 启动程序"
fi 
