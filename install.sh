#!/bin/bash

# 一键安装脚本

# 引入公共函数库
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo -e "${CYAN}${BOLD}========================================${RESET}"
echo -e "${CYAN}${BOLD}    N_m3u8DL-RE 一键安装${RESET}"
echo -e "${CYAN}${BOLD}========================================${RESET}"
echo ""

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 主安装流程
main() {
    echo -e "${BLUE}开始安装N_m3u8DL-RE...${RESET}"
    
    # 安装N_m3u8DL-RE
    if ! download_n_m3u8dl_re "install" "false"; then
        echo -e "${RED}N_m3u8DL-RE 安装失败${RESET}"
        exit 1
    fi
    
    # 安装ffmpeg
    if ! download_ffmpeg "install" "false"; then
        echo -e "${RED}ffmpeg 安装失败${RESET}"
        exit 1
    fi
    
    # 设置脚本权限
    set_permissions
    
    # 自动赋予执行权限
    auto_set_exec_permissions
    
    echo -e "${CYAN}现在可以运行 ./start.sh 启动程序${RESET}"
}

# 运行主函数
main "$@" 
