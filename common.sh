#!/bin/bash

# 公共函数库 - 被所有脚本引用

# 颜色代码
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 配置文件路径
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_FILE="$SCRIPT_DIR/m3u8dl.log"
LOCK_FILE="$SCRIPT_DIR/m3u8dl.lock"

# 默认配置
ThreadCount=32
RetryCount=3
Timeout=10
SaveDir="$SCRIPT_DIR/downloads"
TempDir="$SCRIPT_DIR/temp"
Language="zh-CN"
LogLevel="INFO"
AutoSelect="true"
ConcurrentDownload="true"
RealTimeDecryption="true"
CheckSegments="true"
DeleteAfterDone="false"
WriteMetaJson="true"
AppendUrlParams="true"

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
        local version=$("./N_m3u8DL-RE" --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
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
    version=$(echo "$version" | sed 's/^v//')
    echo "$version"
}

# 下载N_m3u8DL-RE (通用函数)
download_n_m3u8dl_re() {
    local mode="$1"  # "install" 或 "update"
    local backup_old="$2"  # 是否备份旧版本
    
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
    
    # 备份旧版本（仅在更新模式下）
    if [[ "$backup_old" == "true" && -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        mv "$SCRIPT_DIR/N_m3u8DL-RE" "$SCRIPT_DIR/N_m3u8DL-RE.backup"
    fi
    
    cp "$executable" "$SCRIPT_DIR/N_m3u8DL-RE"
    chmod +x "$SCRIPT_DIR/N_m3u8DL-RE"
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    if [[ "$mode" == "install" ]]; then
        echo -e "${GREEN}N_m3u8DL-RE 安装完成${RESET}"
    else
        echo -e "${GREEN}N_m3u8DL-RE 更新完成${RESET}"
    fi
    return 0
}

# 下载ffmpeg (通用函数)
download_ffmpeg() {
    local mode="$1"  # "install" 或 "update"
    local backup_old="$2"  # 是否备份旧版本
    
    echo -e "${BLUE}开始检查ffmpeg...${RESET}"
    
    if ! check_network; then
        return 1
    fi
    
    local arch=$(get_system_arch)
    if [[ "$arch" == "unknown" ]]; then
        echo -e "${RED}不支持的架构${RESET}"
        return 1
    fi
    
    # 检查本地ffmpeg是否存在
    if [[ ! -f "$SCRIPT_DIR/ffmpeg" ]]; then
        echo -e "${BLUE}本地未找到ffmpeg，开始下载...${RESET}"
    else
        # 获取本地版本
        local local_version=$("$SCRIPT_DIR/ffmpeg" -version | head -1)
        echo -e "${BLUE}本地版本: ${local_version}${RESET}"
    fi
    
    # 下载并检查版本
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
    
    # 检查版本（仅在更新模式下）
    if [[ "$mode" == "update" && -f "$SCRIPT_DIR/ffmpeg" ]]; then
        local remote_version=$("$ffmpeg_executable" -version | head -1)
        echo -e "${BLUE}远程版本: ${remote_version}${RESET}"
        
        if [[ "$local_version" == "$remote_version" ]]; then
            echo -e "${GREEN}ffmpeg 已是最新版本，无需更新${RESET}"
            cd "$SCRIPT_DIR"
            rm -rf "$temp_dir"
            return 0
        fi
    fi
    
    # 备份旧版本（仅在更新模式下）
    if [[ "$backup_old" == "true" && -f "$SCRIPT_DIR/ffmpeg" ]]; then
        mv "$SCRIPT_DIR/ffmpeg" "$SCRIPT_DIR/ffmpeg.backup"
    fi
    
    cp "$ffmpeg_executable" "$SCRIPT_DIR/ffmpeg"
    chmod +x "$SCRIPT_DIR/ffmpeg"
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    if [[ "$mode" == "install" ]]; then
        echo -e "${GREEN}ffmpeg 安装完成${RESET}"
    else
        echo -e "${GREEN}ffmpeg 更新完成${RESET}"
    fi
    return 0
}

# 设置权限
set_permissions() {
    echo -e "${BLUE}设置执行权限...${RESET}"
    chmod +x m3u8DL_enhanced.sh 2>/dev/null
    chmod +x auto_update.sh 2>/dev/null
    chmod +x install.sh 2>/dev/null
    chmod +x start.sh 2>/dev/null
    chmod +x advanced.sh 2>/dev/null
    echo -e "${GREEN}权限设置完成${RESET}"
}

# 自动赋予执行权限
auto_set_exec_permissions() {
    if [[ -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        chmod +x "$SCRIPT_DIR/N_m3u8DL-RE"
        echo -e "\033[0;32m已为 N_m3u8DL-RE 添加执行权限\033[0m"
    fi
    if [[ -f "$SCRIPT_DIR/ffmpeg" ]]; then
        chmod +x "$SCRIPT_DIR/ffmpeg"
        echo -e "\033[0;32m已为 ffmpeg 添加执行权限\033[0m"
    fi
    echo -e "\033[0;36m安装完成！如遇无法执行请手动运行：chmod +x N_m3u8DL-RE ffmpeg\033[0m"
}

# 加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        save_config
    fi
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" << EOF
# 配置文件
ThreadCount=$ThreadCount
RetryCount=$RetryCount
Timeout=$Timeout
SaveDir="$SaveDir"
TempDir="$TempDir"
Language=$Language
LogLevel=$LogLevel
AutoSelect=$AutoSelect
ConcurrentDownload=$ConcurrentDownload
RealTimeDecryption=$RealTimeDecryption
CheckSegments=$CheckSegments
DeleteAfterDone=$DeleteAfterDone
WriteMetaJson=$WriteMetaJson
AppendUrlParams=$AppendUrlParams
EOF
}

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR") echo -e "${RED}[ERROR] $message${RESET}" ;;
        "WARN")  echo -e "${YELLOW}[WARN] $message${RESET}" ;;
        "INFO")  echo -e "${BLUE}[INFO] $message${RESET}" ;;
    esac
}

# 检查程序
check_programs() {
    if [[ ! -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        echo -e "${RED}错误: N_m3u8DL-RE 程序不存在${RESET}"
        echo -e "${YELLOW}请运行 ./install.sh 安装程序${RESET}"
        exit 1
    fi
    
    if [[ ! -f "$SCRIPT_DIR/ffmpeg" ]]; then
        echo -e "${RED}错误: ffmpeg 程序不存在${RESET}"
        echo -e "${YELLOW}请运行 ./install.sh 安装程序${RESET}"
        exit 1
    fi
    
    chmod +x "$SCRIPT_DIR/N_m3u8DL-RE" 2>/dev/null
    chmod +x "$SCRIPT_DIR/ffmpeg" 2>/dev/null
}

# 创建目录
create_directories() {
    mkdir -p "$SaveDir"
    mkdir -p "$TempDir"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# 显示美化标题
show_title() {
    local title="$1"
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}${BOLD}║                    $title${RESET}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# 显示进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %d%%" "$percentage"
    
    if [[ "$current" -eq "$total" ]]; then
        echo ""
    fi
}

# 显示确认对话框
confirm_action() {
    local message="$1"
    echo -e "${YELLOW}$message${RESET}"
    read -p "确认操作? (y/N): " confirm
    [[ "$confirm" == "y" || "$confirm" == "Y" ]]
}

# 显示输入框
input_box() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " input
        echo "${input:-$default}"
    else
        read -p "$prompt: " input
        echo "$input"
    fi
}

# 显示选择菜单
show_selection_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    show_title "$title"
    for i in "${!options[@]}"; do
        echo -e "${WHITE}$((i+1)). ${options[i]}${RESET}"
    done
    echo -e "${WHITE}0. 返回${RESET}"
    echo ""
}

# 获取用户选择
get_user_choice() {
    local max="$1"
    local choice
    
    while true; do
        read -p "请选择 (0-$max): " choice
        # 检查是否为空
        if [[ -z "$choice" ]]; then
            echo -e "${RED}请输入有效选择${RESET}"
            continue
        fi
        # 检查是否为数字且在有效范围内
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 0 ]] && [[ "$choice" -le "$max" ]]; then
            echo "$choice"
            return 0
        else
            echo -e "${RED}无效选择，请输入 0-$max${RESET}"
        fi
    done
} 
