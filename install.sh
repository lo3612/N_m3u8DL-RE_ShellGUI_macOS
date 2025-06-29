#!/bin/bash

# 一键安装脚本

# 颜色代码
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

echo -e "${CYAN}${BOLD}========================================${RESET}"
echo -e "${CYAN}${BOLD}    N_m3u8DL-RE 一键安装${RESET}"
echo -e "${CYAN}${BOLD}========================================${RESET}"
echo ""

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查系统架构
get_system_arch() {
    local arch=$(uname -m)
    case "$arch" in
        "arm64"|"aarch64") echo "osx-arm64" ;;
        "x86_64") echo "osx-x64" ;;
        *) echo "unknown" ;;
    esac
}

# 检查网络连接
check_network() {
    echo -e "${BLUE}检查网络连接...${RESET}"
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${RED}网络连接失败${RESET}"
        return 1
    fi
    echo -e "${GREEN}网络连接正常${RESET}"
    return 0
}

# 下载N_m3u8DL-RE
download_n_m3u8dl_re() {
    echo -e "${BLUE}开始下载N_m3u8DL-RE...${RESET}"
    
    if ! check_network; then
        return 1
    fi
    
    local arch=$(get_system_arch)
    if [[ "$arch" == "unknown" ]]; then
        echo -e "${RED}不支持的架构${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}获取最新版本信息...${RESET}"
    local response=$(curl -s "https://api.github.com/repos/nilaoda/N_m3u8DL-RE/releases/latest")
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}无法获取版本信息${RESET}"
        return 1
    fi
    
    local version=$(echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    local download_url=""
    
    if [[ "$arch" == "osx-arm64" ]]; then
        download_url=$(echo "$response" | grep -o '"browser_download_url": "[^"]*osx-arm64[^"]*\.tar\.gz"' | cut -d'"' -f4)
    elif [[ "$arch" == "osx-x64" ]]; then
        download_url=$(echo "$response" | grep -o '"browser_download_url": "[^"]*osx-x64[^"]*\.tar\.gz"' | cut -d'"' -f4)
    fi
    
    if [[ -z "$download_url" ]]; then
        echo -e "${RED}未找到对应架构的下载链接${RESET}"
        return 1
    fi
    
    echo -e "${GREEN}找到最新版本: $version${RESET}"
    
    local temp_dir="$SCRIPT_DIR/temp"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    local filename="N_m3u8DL-RE_${version}.tar.gz"
    echo -e "${BLUE}下载中...${RESET}"
    if ! curl -L -o "$filename" "$download_url"; then
        echo -e "${RED}下载失败${RESET}"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${BLUE}解压中...${RESET}"
    if ! tar -xzf "$filename"; then
        echo -e "${RED}解压失败${RESET}"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local executable=$(find . -name "N_m3u8DL-RE" -type f | head -1)
    if [[ -z "$executable" ]]; then
        echo -e "${RED}未找到可执行文件${RESET}"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    cp "$executable" "$SCRIPT_DIR/N_m3u8DL-RE"
    chmod +x "$SCRIPT_DIR/N_m3u8DL-RE"
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}N_m3u8DL-RE 安装完成${RESET}"
    return 0
}

# 下载ffmpeg
download_ffmpeg() {
    echo -e "${BLUE}开始下载ffmpeg...${RESET}"
    
    if ! check_network; then
        return 1
    fi
    
    local arch=$(get_system_arch)
    if [[ "$arch" == "unknown" ]]; then
        echo -e "${RED}不支持的架构${RESET}"
        return 1
    fi
    
    local temp_dir="$SCRIPT_DIR/temp"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    echo -e "${BLUE}下载中...${RESET}"
    if ! curl -L -o "ffmpeg.zip" "https://evermeet.cx/ffmpeg/getrelease/zip"; then
        echo -e "${RED}下载ffmpeg失败${RESET}"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${BLUE}解压中...${RESET}"
    if ! unzip -q "ffmpeg.zip"; then
        echo -e "${RED}解压ffmpeg失败${RESET}"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local ffmpeg_executable=$(find . -name "ffmpeg" -type f | head -1)
    if [[ -z "$ffmpeg_executable" ]]; then
        echo -e "${RED}未找到ffmpeg可执行文件${RESET}"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    cp "$ffmpeg_executable" "$SCRIPT_DIR/ffmpeg"
    chmod +x "$SCRIPT_DIR/ffmpeg"
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}ffmpeg 安装完成${RESET}"
    return 0
}

# 设置权限
set_permissions() {
    echo -e "${BLUE}设置执行权限...${RESET}"
    chmod +x m3u8DL_enhanced.sh 2>/dev/null
    chmod +x auto_update.sh 2>/dev/null
    chmod +x start.sh 2>/dev/null
    chmod +x advanced.sh 2>/dev/null
    echo -e "${GREEN}权限设置完成${RESET}"
}

# 主安装流程
main() {
    echo -e "${BLUE}开始安装...${RESET}"
    echo ""
    
    # 下载N_m3u8DL-RE
    if ! download_n_m3u8dl_re; then
        echo -e "${RED}N_m3u8DL-RE 安装失败${RESET}"
        exit 1
    fi
    
    echo ""
    
    # 下载ffmpeg
    if ! download_ffmpeg; then
        echo -e "${RED}ffmpeg 安装失败${RESET}"
        exit 1
    fi
    
    echo ""
    
    # 设置权限
    set_permissions
    
    echo ""
    echo -e "${GREEN}${BOLD}安装完成!${RESET}"
    echo -e "${CYAN}现在可以运行 ./start.sh 启动程序${RESET}"
}

# 运行主函数
main 