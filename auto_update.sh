#!/bin/bash

# 自动更新脚本

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
echo -e "${CYAN}${BOLD}    N_m3u8DL-RE 自动更新${RESET}"
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

# 获取本地版本
get_local_version() {
    if [[ -f "N_m3u8DL-RE" ]]; then
        local version=$("./N_m3u8DL-RE" --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo "$version"
    else
        echo ""
    fi
}

# 获取远程版本
get_remote_version() {
    local response=$(curl -s "https://api.github.com/repos/nilaoda/N_m3u8DL-RE/releases/latest")
    if [[ $? -ne 0 ]]; then
        echo ""
        return 1
    fi
    
    local version=$(echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    echo "$version"
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
    
    # 备份旧版本
    if [[ -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        mv "$SCRIPT_DIR/N_m3u8DL-RE" "$SCRIPT_DIR/N_m3u8DL-RE.backup"
    fi
    
    cp "$executable" "$SCRIPT_DIR/N_m3u8DL-RE"
    chmod +x "$SCRIPT_DIR/N_m3u8DL-RE"
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}N_m3u8DL-RE 更新完成${RESET}"
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
    
    # 备份旧版本
    if [[ -f "$SCRIPT_DIR/ffmpeg" ]]; then
        mv "$SCRIPT_DIR/ffmpeg" "$SCRIPT_DIR/ffmpeg.backup"
    fi
    
    cp "$ffmpeg_executable" "$SCRIPT_DIR/ffmpeg"
    chmod +x "$SCRIPT_DIR/ffmpeg"
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}ffmpeg 更新完成${RESET}"
    return 0
}

# 检查更新
check_updates() {
    echo -e "${BLUE}检查更新...${RESET}"
    
    local local_version=$(get_local_version)
    local remote_version=$(get_remote_version)
    
    if [[ -z "$remote_version" ]]; then
        echo -e "${RED}无法获取远程版本信息${RESET}"
        return 1
    fi
    
    echo -e "本地版本: ${YELLOW}${local_version:-"未安装"}${RESET}"
    echo -e "远程版本: ${GREEN}$remote_version${RESET}"
    
    if [[ -z "$local_version" ]]; then
        echo -e "${YELLOW}本地未安装，将进行首次安装${RESET}"
        return 0
    fi
    
    if [[ "$local_version" == "$remote_version" ]]; then
        echo -e "${GREEN}已是最新版本${RESET}"
        return 2
    else
        echo -e "${YELLOW}发现新版本，需要更新${RESET}"
        return 0
    fi
}

# 清理备份
cleanup_backups() {
    echo -e "${BLUE}清理备份文件...${RESET}"
    
    if [[ -f "N_m3u8DL-RE.backup" ]]; then
        rm -f "N_m3u8DL-RE.backup"
        echo -e "${GREEN}已清理N_m3u8DL-RE备份${RESET}"
    fi
    
    if [[ -f "ffmpeg.backup" ]]; then
        rm -f "ffmpeg.backup"
        echo -e "${GREEN}已清理ffmpeg备份${RESET}"
    fi
}

# 主更新流程
main() {
    local update_n_m3u8dl=false
    local update_ffmpeg=false
    
    # 检查参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --n-m3u8dl)
                update_n_m3u8dl=true
                shift
                ;;
            --ffmpeg)
                update_ffmpeg=true
                shift
                ;;
            --all)
                update_n_m3u8dl=true
                update_ffmpeg=true
                shift
                ;;
            --cleanup)
                cleanup_backups
                exit 0
                ;;
            *)
                echo -e "${RED}未知参数: $1${RESET}"
                echo -e "用法: $0 [--n-m3u8dl|--ffmpeg|--all|--cleanup]"
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定参数，检查所有组件
    if [[ "$update_n_m3u8dl" == "false" && "$update_ffmpeg" == "false" ]]; then
        update_n_m3u8dl=true
        update_ffmpeg=true
    fi
    
    # 更新N_m3u8DL-RE
    if [[ "$update_n_m3u8dl" == "true" ]]; then
        echo ""
        echo -e "${CYAN}=== 更新N_m3u8DL-RE ===${RESET}"
        
        local check_result
        check_updates
        check_result=$?
        
        if [[ $check_result -eq 0 ]]; then
            if ! download_n_m3u8dl_re; then
                echo -e "${RED}N_m3u8DL-RE 更新失败${RESET}"
                exit 1
            fi
        elif [[ $check_result -eq 2 ]]; then
            echo -e "${GREEN}N_m3u8DL-RE 已是最新版本${RESET}"
        fi
    fi
    
    # 更新ffmpeg
    if [[ "$update_ffmpeg" == "true" ]]; then
        echo ""
        echo -e "${CYAN}=== 更新ffmpeg ===${RESET}"
        
        if [[ ! -f "ffmpeg" ]]; then
            echo -e "${YELLOW}ffmpeg未安装，将进行首次安装${RESET}"
        fi
        
        if ! download_ffmpeg; then
            echo -e "${RED}ffmpeg 更新失败${RESET}"
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}更新完成!${RESET}"
    echo -e "${CYAN}现在可以运行 ./start.sh 启动程序${RESET}"
}

# 运行主函数
main "$@" 