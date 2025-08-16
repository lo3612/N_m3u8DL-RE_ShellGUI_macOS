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

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}检查系统依赖...${RESET}"
    log "INFO" "检查系统依赖"
    
    local missing_deps=()
    
    # 检查 curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # 检查 tar
    if ! command -v tar >/dev/null 2>&1; then
        missing_deps+=("tar")
    fi
    
    # 检查 unzip
    if ! command -v unzip >/dev/null 2>&1; then
        missing_deps+=("unzip")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}缺少依赖: ${missing_deps[*]}${RESET}"
        log "ERROR" "缺少依赖: ${missing_deps[*]}"
        echo -e "${YELLOW}请先安装这些依赖再继续${RESET}"
        return 1
    else
        echo -e "${GREEN}所有依赖检查通过${RESET}"
        log "INFO" "所有依赖检查通过"
        return 0
    fi
}

# 主安装流程
main() {
    # 检查依赖
    if ! check_dependencies; then
        exit 1
    fi
    
    # 检查磁盘空间
    echo -e "${BLUE}检查磁盘空间...${RESET}"
    local required_space=200  # MB
    local available_space=$(df "$SCRIPT_DIR" | awk 'NR==2 {print int($4/1024)}')
    
    if [[ $available_space -lt $required_space ]]; then
        echo -e "${RED}磁盘空间不足，需要至少 ${required_space}MB 可用空间${RESET}"
        log "ERROR" "磁盘空间不足，需要至少 ${required_space}MB 可用空间，当前可用 ${available_space}MB"
        exit 1
    else
        echo -e "${GREEN}磁盘空间充足 (${available_space}MB 可用)${RESET}"
        log "INFO" "磁盘空间充足 (${available_space}MB 可用)"
    fi
    
    # 安装N_m3u8DL-RE
    echo ""
    echo -e "${CYAN}=== 安装N_m3u8DL-RE ===${RESET}"
    if ! download_n_m3u8dl_re "install" "false"; then
        echo -e "${RED}N_m3u8DL-RE 安装失败${RESET}"
        log "ERROR" "N_m3u8DL-RE 安装失败"
        exit 1
    fi
    
    # 安装ffmpeg
    echo ""
    echo -e "${CYAN}=== 安装ffmpeg ===${RESET}"
    if ! download_ffmpeg "install" "false"; then
        echo -e "${RED}ffmpeg 安装失败${RESET}"
        log "ERROR" "ffmpeg 安装失败"
        exit 1
    fi
    
    # 设置权限
    echo ""
    echo -e "${CYAN}=== 设置权限 ===${RESET}"
    auto_set_exec_permissions
    
    # 创建必要目录
    echo ""
    echo -e "${CYAN}=== 创建目录 ===${RESET}"
    create_directories
    
    echo ""
    echo -e "${GREEN}${BOLD}安装完成!${RESET}"
    log "INFO" "安装完成"
    echo -e "${CYAN}现在可以运行 ./start.sh 启动程序${RESET}"
}

# 运行主函数
main "$@"