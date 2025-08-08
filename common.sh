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
ThreadCount=16
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
    echo -e "${BLUE}正在检查网络连接...${RESET}"
    
    # 尝试使用curl检查网络连接
    if command -v curl >/dev/null 2>&1; then
        if curl -s --head https://github.com > /dev/null; then
            echo -e "${GREEN}网络连接正常${RESET}"
            log "INFO" "网络连接检查成功"
            return 0
        else
            echo -e "${RED}网络连接失败${RESET}"
            log "ERROR" "网络连接检查失败"
            return 1
        fi
    else
        # 如果没有安装curl，使用ping检查
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            echo -e "${GREEN}网络连接正常${RESET}"
            log "INFO" "网络连接检查成功"
            return 0
        else
            echo -e "${RED}网络连接失败${RESET}"
            log "ERROR" "网络连接检查失败"
            return 1
        fi
    fi
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
    log "INFO" "开始下载N_m3u8DL-RE ($mode 模式)"
    
    if ! check_network; then
        echo -e "${RED}网络检查失败，下载中止${RESET}"
        log "ERROR" "网络检查失败，下载中止"
        return 1
    fi
    
    local arch=$(get_system_arch)
    if [[ "$arch" == "unknown" ]]; then
        echo -e "${RED}不支持的架构${RESET}"
        log "ERROR" "不支持的架构: $arch"
        return 1
    fi
    
    echo -e "${BLUE}系统架构: ${arch}${RESET}"
    log "INFO" "检测到系统架构: $arch"
    
    echo -e "${BLUE}获取最新版本信息...${RESET}"
    local response=""
    local retry_count=3
    
    # 重试机制
    for i in $(seq 1 $retry_count); do
        response=$(curl -s --connect-timeout 10 "https://api.github.com/repos/nilaoda/N_m3u8DL-RE/releases/latest")
        if [[ $? -eq 0 && -n "$response" ]]; then
            break
        else
            echo -e "${YELLOW}获取版本信息失败，第 $i 次重试...${RESET}"
            log "WARN" "获取版本信息失败，第 $i 次重试"
            sleep 2
        fi
    done
    
    if [[ -z "$response" ]]; then
        echo -e "${RED}无法获取版本信息${RESET}"
        log "ERROR" "无法获取版本信息，重试 $retry_count 次后仍然失败"
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
        log "ERROR" "未找到对应架构的下载链接: $arch"
        return 1
    fi
    
    echo -e "${GREEN}找到最新版本: $version${RESET}"
    log "INFO" "找到最新版本: $version"
    
    # 检查本地版本（如果存在）
    if [[ -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        local local_version=""
        local local_version_output=$("$SCRIPT_DIR/N_m3u8DL-RE" --version 2>&1)
        if [[ $? -eq 0 ]]; then
            local_version=$(echo "$local_version_output" | head -1)
            echo -e "${BLUE}本地版本: ${local_version}${RESET}"
            log "INFO" "本地版本: ${local_version}"
            
            # 提取版本号进行比较（只比较主版本号）
            local local_ver_num=$(echo "$local_version" | grep -o '^[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            local remote_ver_num=$(echo "$version" | sed 's/^v//' | sed 's/-.*$//')
            
            if [[ "$local_ver_num" == "$remote_ver_num" ]]; then
                echo -e "${GREEN}N_m3u8DL-RE 已是最新版本，无需下载${RESET}"
                log "INFO" "N_m3u8DL-RE 已是最新版本，无需下载"
                return 0
            fi
        else
            echo -e "${YELLOW}无法获取本地版本信息: $local_version_output${RESET}"
            log "WARN" "无法获取本地版本信息: $local_version_output"
        fi
    fi
    
    local temp_dir="$SCRIPT_DIR/temp"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    local filename="N_m3u8DL-RE_${version}.tar.gz"
    echo -e "${BLUE}下载中...${RESET}"
    log "INFO" "开始下载: $filename"
    
    # 添加下载进度和重试机制
    local download_success=false
    for i in $(seq 1 $retry_count); do
        if curl -L -o "$filename" "$download_url"; then
            download_success=true
            break
        else
            echo -e "${YELLOW}下载失败，第 $i 次重试...${RESET}"
            log "WARN" "下载失败，第 $i 次重试"
            sleep 2
        fi
    done
    
    if [[ "$download_success" == false ]]; then
        echo -e "${RED}下载失败${RESET}"
        log "ERROR" "下载失败，重试 $retry_count 次后仍然失败"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${BLUE}解压中...${RESET}"
    log "INFO" "开始解压: $filename"
    if ! tar -xzf "$filename"; then
        echo -e "${RED}解压失败${RESET}"
        log "ERROR" "解压失败: $filename"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local executable=$(find . -name "N_m3u8DL-RE" -type f | head -1)
    if [[ -z "$executable" ]]; then
        echo -e "${RED}未找到可执行文件${RESET}"
        log "ERROR" "未找到可执行文件"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 备份旧版本（仅在更新模式下）
    if [[ "$backup_old" == "true" && -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        echo -e "${BLUE}备份旧版本...${RESET}"
        if mv "$SCRIPT_DIR/N_m3u8DL-RE" "$SCRIPT_DIR/N_m3u8DL-RE.backup"; then
            echo -e "${GREEN}旧版本已备份${RESET}"
            log "INFO" "旧版本已备份"
        else
            echo -e "${YELLOW}备份旧版本失败${RESET}"
            log "WARN" "备份旧版本失败"
        fi
    fi
    
    echo -e "${BLUE}安装新版本...${RESET}"
    if cp "$executable" "$SCRIPT_DIR/N_m3u8DL-RE" && chmod +x "$SCRIPT_DIR/N_m3u8DL-RE"; then
        echo -e "${GREEN}N_m3u8DL-RE 安装完成${RESET}"
        log "INFO" "N_m3u8DL-RE 安装完成"
    else
        echo -e "${RED}N_m3u8DL-RE 安装失败${RESET}"
        log "ERROR" "N_m3u8DL-RE 安装失败"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    if [[ "$mode" == "install" ]]; then
        echo -e "${GREEN}N_m3u8DL-RE 安装完成${RESET}"
        log "INFO" "N_m3u8DL-RE 安装完成"
    else
        echo -e "${GREEN}N_m3u8DL-RE 更新完成${RESET}"
        log "INFO" "N_m3u8DL-RE 更新完成"
    fi
    return 0
}

# 下载ffmpeg (通用函数)
download_ffmpeg() {
    local mode="$1"  # "install" 或 "update"
    local backup_old="$2"  # 是否备份旧版本
    
    echo -e "${BLUE}开始检查ffmpeg...${RESET}"
    log "INFO" "开始检查ffmpeg ($mode 模式)"
    
    if ! check_network; then
        echo -e "${RED}网络检查失败，下载中止${RESET}"
        log "ERROR" "网络检查失败，下载中止"
        return 1
    fi
    
    local arch=$(get_system_arch)
    if [[ "$arch" == "unknown" ]]; then
        echo -e "${RED}不支持的架构${RESET}"
        log "ERROR" "不支持的架构: $arch"
        return 1
    fi
    
    echo -e "${BLUE}系统架构: ${arch}${RESET}"
    log "INFO" "检测到系统架构: $arch"
    
    # 检查本地ffmpeg是否存在
    if [[ ! -f "$SCRIPT_DIR/ffmpeg" ]]; then
        echo -e "${BLUE}本地未找到ffmpeg，开始下载...${RESET}"
        log "INFO" "未找到本地ffmpeg，准备下载"
    else
        # 获取本地版本
        local local_version_output=$("$SCRIPT_DIR/ffmpeg" -version 2>&1)
        if [[ $? -eq 0 ]]; then
            local local_version=$(echo "$local_version_output" | head -1)
            echo -e "${BLUE}本地版本: ${local_version}${RESET}"
            log "INFO" "本地ffmpeg版本: $local_version"
        else
            echo -e "${YELLOW}无法获取本地ffmpeg版本: $local_version_output${RESET}"
            log "WARN" "无法获取本地ffmpeg版本: $local_version_output"
        fi
        
        # 在安装模式下也检查版本
        if [[ "$mode" == "install" ]]; then
            echo -e "${GREEN}ffmpeg 已存在，跳过下载${RESET}"
            log "INFO" "ffmpeg 已存在，跳过下载"
            return 0
        fi
    fi
    
    # 下载并检查版本
    local temp_dir="$SCRIPT_DIR/temp"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    echo -e "${BLUE}下载中...${RESET}"
    log "INFO" "开始下载ffmpeg"
    
    # 添加重试机制
    local retry_count=3
    local download_success=false
    
    for i in $(seq 1 $retry_count); do
        if curl -L -o "ffmpeg.zip" "https://evermeet.cx/ffmpeg/getrelease/zip"; then
            download_success=true
            break
        else
            echo -e "${YELLOW}下载失败，第 $i 次重试...${RESET}"
            log "WARN" "ffmpeg下载失败，第 $i 次重试"
            sleep 2
        fi
    done
    
    if [[ "$download_success" == false ]]; then
        echo -e "${RED}下载ffmpeg失败${RESET}"
        log "ERROR" "下载ffmpeg失败，重试 $retry_count 次后仍然失败"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${BLUE}解压中...${RESET}"
    log "INFO" "开始解压ffmpeg"
    if ! unzip -q "ffmpeg.zip"; then
        echo -e "${RED}解压ffmpeg失败${RESET}"
        log "ERROR" "解压ffmpeg失败"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local ffmpeg_executable=$(find . -name "ffmpeg" -type f | head -1)
    if [[ -z "$ffmpeg_executable" ]]; then
        echo -e "${RED}未找到ffmpeg可执行文件${RESET}"
        log "ERROR" "未找到ffmpeg可执行文件"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 检查版本（仅在更新模式下）
    if [[ "$mode" == "update" && -f "$SCRIPT_DIR/ffmpeg" ]]; then
        local remote_version_output=$("$ffmpeg_executable" -version 2>&1)
        if [[ $? -eq 0 ]]; then
            local remote_version=$(echo "$remote_version_output" | head -1)
            echo -e "${BLUE}远程版本: ${remote_version}${RESET}"
            log "INFO" "远程ffmpeg版本: $remote_version"
            
            if [[ "$local_version" == "$remote_version" ]]; then
                echo -e "${GREEN}ffmpeg 已是最新版本，无需更新${RESET}"
                log "INFO" "ffmpeg 已是最新版本，无需更新"
                cd "$SCRIPT_DIR"
                rm -rf "$temp_dir"
                return 0
            fi
        else
            echo -e "${YELLOW}无法获取远程ffmpeg版本: $remote_version_output${RESET}"
            log "WARN" "无法获取远程ffmpeg版本: $remote_version_output"
        fi
    fi
    
    # 备份旧版本（仅在更新模式下）
    if [[ "$backup_old" == "true" && -f "$SCRIPT_DIR/ffmpeg" ]]; then
        echo -e "${BLUE}备份旧版本...${RESET}"
        if mv "$SCRIPT_DIR/ffmpeg" "$SCRIPT_DIR/ffmpeg.backup"; then
            echo -e "${GREEN}旧版本已备份${RESET}"
            log "INFO" "ffmpeg旧版本已备份"
        else
            echo -e "${YELLOW}备份旧版本失败${RESET}"
            log "WARN" "ffmpeg备份旧版本失败"
        fi
    fi
    
    echo -e "${BLUE}安装新版本...${RESET}"
    if cp "$ffmpeg_executable" "$SCRIPT_DIR/ffmpeg" && chmod +x "$SCRIPT_DIR/ffmpeg"; then
        echo -e "${GREEN}ffmpeg 安装完成${RESET}"
        log "INFO" "ffmpeg 安装完成"
    else
        echo -e "${RED}ffmpeg 安装失败${RESET}"
        log "ERROR" "ffmpeg 安装失败"
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    rm -rf "$temp_dir"
    
    if [[ "$mode" == "install" ]]; then
        echo -e "${GREEN}ffmpeg 安装完成${RESET}"
        log "INFO" "ffmpeg 安装完成"
    else
        echo -e "${GREEN}ffmpeg 更新完成${RESET}"
        log "INFO" "ffmpeg 更新完成"
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

# 检查程序依赖
check_programs() {
    echo -e "${BLUE}正在检查程序依赖...${RESET}"
    local error_occurred=0
    
    # 检查 N_m3u8DL-RE
    if [[ ! -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        echo -e "${RED}错误: 未找到 N_m3u8DL-RE 程序${RESET}"
        echo -e "${YELLOW}请运行 ./install.sh 安装程序${RESET}"
        log "ERROR" "未找到 N_m3u8DL-RE 程序"
        error_occurred=1
    elif [[ ! -x "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        echo -e "${YELLOW}设置 N_m3u8DL-RE 可执行权限...${RESET}"
        if chmod +x "$SCRIPT_DIR/N_m3u8DL-RE"; then
            echo -e "${GREEN}权限设置成功${RESET}"
            log "INFO" "为 N_m3u8DL-RE 设置可执行权限"
        else
            echo -e "${RED}权限设置失败${RESET}"
            log "ERROR" "无法为 N_m3u8DL-RE 设置可执行权限"
        fi
    else
        echo -e "${GREEN}N_m3u8DL-RE 检查通过${RESET}"
        log "INFO" "N_m3u8DL-RE 检查通过"
    fi
    
    # 检查 ffmpeg
    if [[ ! -f "$SCRIPT_DIR/ffmpeg" ]]; then
        echo -e "${RED}错误: 未找到 ffmpeg 程序${RESET}"
        echo -e "${YELLOW}请运行 ./install.sh 安装程序${RESET}"
        log "ERROR" "未找到 ffmpeg 程序"
        error_occurred=1
    elif [[ ! -x "$SCRIPT_DIR/ffmpeg" ]]; then
        echo -e "${YELLOW}设置 ffmpeg 可执行权限...${RESET}"
        if chmod +x "$SCRIPT_DIR/ffmpeg"; then
            echo -e "${GREEN}权限设置成功${RESET}"
            log "INFO" "为 ffmpeg 设置可执行权限"
        else
            echo -e "${RED}权限设置失败${RESET}"
            log "ERROR" "无法为 ffmpeg 设置可执行权限"
        fi
    else
        echo -e "${GREEN}ffmpeg 检查通过${RESET}"
        log "INFO" "ffmpeg 检查通过"
    fi
    
    if [[ $error_occurred -eq 1 ]]; then
        echo -e "${RED}程序依赖检查失败${RESET}"
        log "ERROR" "程序依赖检查失败"
        return 1
    fi
    
    echo -e "${GREEN}所有程序依赖检查完成${RESET}"
    log "INFO" "所有程序依赖检查完成"
    return 0
}

# 创建目录
create_directories() {
    mkdir -p "$SaveDir"
    mkdir -p "$TempDir"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# 获取终端尺寸
get_terminal_size() {
    local cols=$(tput cols 2>/dev/null || echo 80)
    local lines=$(tput lines 2>/dev/null || echo 24)
    echo "$cols $lines"
}

# 计算自适应宽度
get_adaptive_width() {
    local cols=$(get_terminal_size | cut -d' ' -f1)
    local min_width=60
    local max_width=120
    local width=$((cols - 2))  # 只留2个字符的边距
    
    if [[ $width -lt $min_width ]]; then
        width=$min_width
    elif [[ $width -gt $max_width ]]; then
        width=$max_width
    fi
    
    echo "$width"
}

# 生成自适应边框
generate_border() {
    local width="$1"
    local char="$2"
    printf "%${width}s" | tr ' ' "$char"
}

# 显示简洁标题
show_title() {
    local title="$1"
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo -e "${CYAN}${BOLD}  $title${RESET}"
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo ""
}

# 显示简洁菜单
show_menu() {
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

# 显示进度条
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    
    printf "\r["
    printf "%*s" $completed | tr ' ' '█'
    printf "%*s" $((width - completed)) | tr ' ' '░'
    printf "] %d%%" $percentage
    
    if [[ $current -eq $total ]]; then
        echo ""  # 完成后换行
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

# 获取用户选择
get_user_choice() {
    local max="$1"
    local choice
    
    while true; do
        read -p "请选择 (0-$max): " choice
        # 严格检查：只允许数字且在范围内
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 0 && choice <= max )); then
            echo "$choice"
            return 0
        fi
        # 静默处理无效输入，不显示任何错误信息
        :
    done
} 

# 清理空的临时目录
cleanup_empty_temp_dirs() {
    # 删除空的目录，包括只包含.DS_Store文件的目录（MacOS系统文件）
    if [[ -d "$TempDir" ]]; then
        # 先删除所有.DS_Store文件
        find "$TempDir" -name ".DS_Store" -type f -delete 2>/dev/null
        # 再删除所有空目录
        find "$TempDir" -type d -empty -delete 2>/dev/null
    fi
}

# 创建必要目录
create_directories() {
    if [[ ! -d "$SaveDir" ]]; then
        mkdir -p "$SaveDir"
        echo -e "${GREEN}创建下载目录: $SaveDir${RESET}"
    fi
    
    if [[ ! -d "$TempDir" ]]; then
        mkdir -p "$TempDir"
        echo -e "${GREEN}创建临时目录: $TempDir${RESET}"
    fi
}
