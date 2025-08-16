#!/bin/bash
#
# N_m3u8DL-RE 公共函数库
# 提供颜色定义、日志记录、配置管理等基础功能
# 版本: 1.3.0
# 作者: lo3612
# 最后修改: $(date +%Y-%m-%d)

# 严格模式: 遇到错误退出，未定义变量报错
set -euo pipefail
trap 'echo "[ERROR] 脚本异常退出，行号: $LINENO"; exit 1' ERR

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"

# 配置文件路径
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_FILE="$SCRIPT_DIR/m3u8dl.log"
LOCK_FILE="$SCRIPT_DIR/m3u8dl.lock"

# 默认配置
ThreadCount=5
RetryCount=3
Timeout=100
SaveDir="$SCRIPT_DIR/downloads"
TempDir="$SCRIPT_DIR/temp"
Language="zh-CN"
LogLevel="INFO"
AutoSelect="true"
ConcurrentDownload="true"
RealTimeDecryption="true"
CheckSegments="true"
DeleteAfterDone="true"
WriteMetaJson="true"
AppendUrlParams="true"
BinaryMerge="false"
NoDateInfo="false"
UseFFmpegConcatDemuxer="false"
SubOnly="false"
SubFormat="SRT"
AutoSubtitleFix="true"
MaxSpeed=""
CustomRange=""
LivePerformAsVod="false"
LiveRealTimeMerge="false"
LiveKeepSegments="true"
LivePipeMux="false"

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
    if [[ -f "N_m3u8DL-RE" ]] && [[ -x "N_m3u8DL-RE" ]]; then
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

# 版本比较 (version_gt)
# usage: if version_gt "1.2.3" "1.2.2"; then ...
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}
# 检查网络连接和架构
download_validate_network() {
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
    return 0
}

# 获取远程版本信息
download_get_remote_version() {
    echo -e "${BLUE}获取最新版本信息...${RESET}"
    local response=""
    local retry_count=3
    
    for i in $(seq 1 $retry_count); do
        response=$(curl -s --max-time 10 --connect-timeout 10 "https://api.github.com/repos/nilaoda/N_m3u8DL-RE/releases/latest")
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
    echo "$response"
}

# 下载和解压文件 (通用)
download_and_extract() {
    local url="$1"
    local filename="$2"
    local temp_dir="$3"
    local archive_type="$4" # "tar.gz" or "zip"
    local retry_count=3

    (
        cd "$temp_dir" || {
            log "ERROR" "无法进入临时目录: $temp_dir"
            return 1
        }

        echo -e "${BLUE}下载中: $filename...${RESET}"
        log "INFO" "开始下载: $filename"

        for i in $(seq 1 $retry_count); do
            if curl -L --progress-bar --max-time 300 -o "$filename" "$url"; then
                break
            else
                echo -e "${YELLOW}下载失败，第 $i 次重试...${RESET}"
                log "WARN" "下载 $filename 失败，第 $i 次重试"
                sleep 2
                [[ $i -eq $retry_count ]] && return 1
            fi
        done

        echo -e "${BLUE}解压中: $filename...${RESET}"
        log "INFO" "开始解压: $filename"
        if [[ "$archive_type" == "tar.gz" ]]; then
            tar -xzf "$filename" || return 1
        elif [[ "$archive_type" == "zip" ]]; then
            unzip -q "$filename" || return 1
        else
            log "ERROR" "未知的压缩文件类型: $archive_type"
            return 1
        fi
        return 0
    )
}

# 查找并验证可执行文件 (通用)
find_and_validate_executable() {
    local temp_dir="$1"
    local executable_name="$2"

    (
        cd "$temp_dir" || return 1
        local executable=$(find . -name "$executable_name" -type f | head -1)
        [[ -n "$executable" ]] || {
            echo -e "${RED}未找到可执行文件: $executable_name${RESET}"
            log "ERROR" "在 $temp_dir 中未找到可执行文件: $executable_name"
            return 1
        }

        if [[ ! -x "$executable" ]]; then
            chmod +x "$executable" || {
                echo -e "${YELLOW}无法设置执行权限: $executable${RESET}"
                log "WARN" "无法为 $executable 设置执行权限"
                return 1
            }
        fi

        echo "$executable"
        return 0
    )
}

# 备份旧版本 (通用)
backup_old_version() {
    local file_path="$1"
    local backup_path="$1.backup"

    [[ -f "$file_path" ]] || return 0

    echo -e "${BLUE}备份旧版本: $file_path...${RESET}"
    if mv "$file_path" "$backup_path"; then
        echo -e "${GREEN}旧版本已备份至 $backup_path${RESET}"
        log "INFO" "旧版本已备份: $file_path -> $backup_path"
        return 0
    else
        echo -e "${RED}备份旧版本失败: $file_path${RESET}"
        log "ERROR" "备份旧版本失败: $file_path"
        return 1
    fi
}

# 安装新版本 (通用)
install_new_version() {
    local executable_path="$1"
    local destination_path="$2"

    echo -e "${BLUE}安装新版本至: $destination_path...${RESET}"
    if cp "$executable_path" "$destination_path" && chmod +x "$destination_path"; then
        echo -e "${GREEN}安装完成${RESET}"
        log "INFO" "安装完成: $destination_path"
        return 0
    else
        echo -e "${RED}安装失败: $destination_path${RESET}"
        log "ERROR" "安装失败: $destination_path"
        return 1
    fi
}

download_n_m3u8dl_re() {
    local mode="$1"
    local backup_old="$2"
    local force_update="${3:-false}"

    echo -e "${BLUE}开始下载N_m3u8DL-RE...${RESET}"
    log "INFO" "开始下载N_m3u8DL-RE ($mode 模式, 强制: $force_update)"

    if ! download_validate_network; then return 1; fi
    local arch=$(get_system_arch)

    local response=$(download_get_remote_version) || return 1
    local version=$(echo "$response" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    local download_url=$(echo "$response" | grep -o '"browser_download_url": "[^"]*'"$arch"'[^"]*\.tar\.gz"' | cut -d'"' -f4)

    [[ -n "$download_url" ]] || { echo -e "${RED}未找到对应架构 ($arch) 的下载链接${RESET}"; log "ERROR" "未找到 $arch 的下载链接"; return 1; }

    echo -e "${GREEN}找到最新版本: $version${RESET}"
    log "INFO" "找到最新版本: $version"

    if [[ "$force_update" == "false" && -f "$SCRIPT_DIR/N_m3u8DL-RE" ]]; then
        local local_version=$("$SCRIPT_DIR/N_m3u8DL-RE" --version 2>&1 | head -1)
        local local_ver_num=$(echo "$local_version" | grep -o '^[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        local remote_ver_num=$(echo "$version" | sed 's/^v//' | sed 's/-.*$//')
        if [[ "$local_ver_num" == "$remote_ver_num" ]]; then
            echo -e "${GREEN}N_m3u8DL-RE 已是��新版本，无需下载${RESET}"
            return 0
        fi
    fi

    local temp_dir="$SCRIPT_DIR/temp/n_m3u8dl_re"
    mkdir -p "$temp_dir"
    local filename="N_m3u8DL-RE_${version}.tar.gz"

    if ! download_and_extract "$download_url" "$filename" "$temp_dir" "tar.gz"; then
        rm -rf "$temp_dir"
        return 1
    fi

    local executable=$(find_and_validate_executable "$temp_dir" "N_m3u8DL-RE") || { rm -rf "$temp_dir"; return 1; }

    if [[ "$backup_old" == "true" ]]; then
        backup_old_version "$SCRIPT_DIR/N_m3u8DL-RE"
    fi

    if ! install_new_version "$temp_dir/$executable" "$SCRIPT_DIR/N_m3u8DL-RE"; then
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"
    echo -e "${GREEN}N_m3u8DL-RE ${mode}完成${RESET}"
    log "INFO" "N_m3u8DL-RE ${mode}完成"
    return 0
}

download_ffmpeg() {
    local mode="$1"
    local backup_old="$2"
    local force_update="${3:-false}"

    echo -e "${BLUE}开始检查ffmpeg...${RESET}"
    log "INFO" "开始检查ffmpeg ($mode 模式, 强制: $force_update)"

    if ! download_validate_network; then return 1; fi

    if [[ "$force_update" == "false" && -f "$SCRIPT_DIR/ffmpeg" ]]; then
        echo -e "${GREEN}ffmpeg 已存在，跳过下载 (非强制模式)${RESET}"
        log "INFO" "ffmpeg 已存在，跳过下载"
        return 0
    fi

    local temp_dir="$SCRIPT_DIR/temp/ffmpeg"
    mkdir -p "$temp_dir"
    local filename="ffmpeg.zip"
    local download_url="https://evermeet.cx/ffmpeg/getrelease/zip"
    local backup_url="https://www.osxexperts.net/ffmpeg-sd.zip"

    if ! download_and_extract "$download_url" "$filename" "$temp_dir" "zip" && \
       ! download_and_extract "$backup_url" "$filename" "$temp_dir" "zip"; then
        echo -e "${RED}ffmpeg 下载失败，已尝试所有下载源${RESET}"
        log "ERROR" "ffmpeg 下载失败"
        rm -rf "$temp_dir"
        return 1
    fi

    local executable=$(find_and_validate_executable "$temp_dir" "ffmpeg") || { rm -rf "$temp_dir"; return 1; }

    if [[ "$backup_old" == "true" ]]; then
        backup_old_version "$SCRIPT_DIR/ffmpeg"
    fi

    if ! install_new_version "$temp_dir/$executable" "$SCRIPT_DIR/ffmpeg"; then
        rm -rf "$temp_dir"
        return 1
    fi

    rm -rf "$temp_dir"
    echo -e "${GREEN}ffmpeg ${mode}完成${RESET}"
    log "INFO" "ffmpeg ${mode}完成"
    return 0
}

# 设置权限
set_permissions() {
    echo -e "${BLUE}设置执行权限...${RESET}"
    chmod +x m3u8DL_enhanced.sh 2>/dev/null
    chmod +x auto_update.sh 2>/dev/null
    chmod +x install.sh 2>/dev/null
    chmod +x start.sh 2>/dev/null
    chmod +x modules/*.sh 2>/dev/null
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

# 获取配置
get_config() {
    local key="$1"
    local default_value="$2"
    local value=$(grep "^${key}=" "$CONFIG_FILE" | cut -d'=' -f2- | sed 's/"//g')
    echo "${value:-$default_value}"
}

# 设置配置
set_config() {
    local key="$1"
    local value="$2"
    
    # 如果配置文件中已存在该键，则替换它
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i.bak "s|^${key}=.*|${key}=\"${value}\"|" "$CONFIG_FILE"
        rm -f "${CONFIG_FILE}.bak"
    else
        # 否则，将新键值对追加到文件末尾
        echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
    fi
}

# 加载配置
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        touch "$CONFIG_FILE"
        save_config # 保存默认配置
    fi
    
    # 从配置文件加载所有变量
    ThreadCount=$(get_config "ThreadCount" "16")
    RetryCount=$(get_config "RetryCount" "3")
    Timeout=$(get_config "Timeout" "100")
    SaveDir=$(get_config "SaveDir" "$SCRIPT_DIR/downloads")
    TempDir=$(get_config "TempDir" "$SCRIPT_DIR/temp")
    Language=$(get_config "Language" "zh-CN")
    LogLevel=$(get_config "LogLevel" "INFO")
    AutoSelect=$(get_config "AutoSelect" "true")
    ConcurrentDownload=$(get_config "ConcurrentDownload" "true")
    RealTimeDecryption=$(get_config "RealTimeDecryption" "true")
    CheckSegments=$(get_config "CheckSegments" "true")
    DeleteAfterDone=$(get_config "DeleteAfterDone" "true")
    WriteMetaJson=$(get_config "WriteMetaJson" "true")
    AppendUrlParams=$(get_config "AppendUrlParams" "true")
    BinaryMerge=$(get_config "BinaryMerge" "false")
    NoDateInfo=$(get_config "NoDateInfo" "false")
    UseFFmpegConcatDemuxer=$(get_config "UseFFmpegConcatDemuxer" "false")
    SubOnly=$(get_config "SubOnly" "false")
    SubFormat=$(get_config "SubFormat" "SRT")
    AutoSubtitleFix=$(get_config "AutoSubtitleFix" "true")
    MaxSpeed=$(get_config "MaxSpeed" "")
    CustomRange=$(get_config "CustomRange" "")
    LivePerformAsVod=$(get_config "LivePerformAsVod" "false")
    LiveRealTimeMerge=$(get_config "LiveRealTimeMerge" "false")
    LiveKeepSegments=$(get_config "LiveKeepSegments" "true")
    LivePipeMux=$(get_config "LivePipeMux" "false")
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" << EOF
# N_m3u8DL-RE 配置文件
# 生成时间: $(date)

ThreadCount="$ThreadCount"
RetryCount="$RetryCount"
Timeout="$Timeout"
SaveDir="$SaveDir"
TempDir="$TempDir"
Language="$Language"
LogLevel="$LogLevel"
AutoSelect="$AutoSelect"
ConcurrentDownload="$ConcurrentDownload"
RealTimeDecryption="$RealTimeDecryption"
CheckSegments="$CheckSegments"
DeleteAfterDone="$DeleteAfterDone"
WriteMetaJson="$WriteMetaJson"
AppendUrlParams="$AppendUrlParams"
BinaryMerge="$BinaryMerge"
NoDateInfo="$NoDateInfo"
UseFFmpegConcatDemuxer="$UseFFmpegConcatDemuxer"
SubOnly="$SubOnly"
SubFormat="$SubFormat"
AutoSubtitleFix="$AutoSubtitleFix"
MaxSpeed="$MaxSpeed"
CustomRange="$CustomRange"
LivePerformAsVod="$LivePerformAsVod"
LiveRealTimeMerge="$LiveRealTimeMerge"
LiveKeepSegments="$LiveKeepSegments"
LivePipeMux="$LivePipeMux"
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
    
    # 防止除零错误
    if [[ $total -eq 0 ]]; then
        printf "\r["
        printf "%*s" $width | tr ' ' '░'
        printf "] 0%%"
        return
    fi
    
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

# 显���输入框
input_box() {
    local prompt="$1"
    local default="${2:-}"  # 安全地处理第二个参数，如果未提供则为空
    local input
    
    if [[ -n "$default" ]]; then
        read -e -p "$prompt [$default]: " input
        echo "${input:-$default}"
    else
        read -e -p "$prompt: " input
        echo "$input"
    fi
}

# 获取用户选择
get_user_choice() {
    local max="$1"
    local prompt_msg="$2"
    local choice

    if [[ -z "$prompt_msg" ]]; then
        prompt_msg="请选择 (0-$max): "
    fi
    
    while true; do
        read -p "$prompt_msg" choice
        # 严格检查：只允许数字且在范围内
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 0 && choice <= max )); then
            echo "$choice"
            return 0
        fi
        echo -e "${RED}无效输入，请输入 0 到 $max 之间的数字${RESET}"
    done
}

# 获取布尔值选择
get_boolean_choice() {
    local prompt_msg="$1"
    local current_value="$2"
    
    echo "$prompt_msg"
    if [[ "$current_value" == "true" ]]; then
        echo -e "当前状态: ${GREEN}开启${RESET}"
        echo "1. 关闭"
        echo "2. 保持开启"
    else
        echo -e "当前状态: ${RED}关闭${RESET}"
        echo "1. 开启"
        echo "2. 保持关闭"
    fi

    local choice=$(get_user_choice 2 "请选择: ")
    
    if [[ "$current_value" == "true" ]]; then
        [[ "$choice" -eq 1 ]] && echo "false" || echo "true"
    else
        [[ "$choice" -eq 1 ]] && echo "true" || echo "false"
    fi
}

# 清理空的临时目录
cleanup_empty_temp_dirs() {
    find "$TempDir" -type d -empty -delete 2>/dev/null
}


# 清理备份
cleanup_backups() {
    echo -e "${BLUE}清理备份文件...${RESET}"
    log "INFO" "清理备份文件"
    
    local cleaned=false
    
    if [[ -f "N_m3u8DL-RE.backup" ]]; then
        rm -f "N_m3u8DL-RE.backup"
        echo -e "${GREEN}已清理N_m3u8DL-RE备份${RESET}"
        log "INFO" "已清理N_m3u8DL-RE备份"
        cleaned=true
    fi
    
    if [[ -f "ffmpeg.backup" ]]; then
        rm -f "ffmpeg.backup"
        echo -e "${GREEN}已清理ffmpeg备份${RESET}"
        log "INFO" "已清理ffmpeg备份"
        cleaned=true
    fi
    
    if [[ "$cleaned" == false ]]; then
        echo -e "${BLUE}没有备份文件需要清理${RESET}"
        log "INFO" "没有备份文件需要清理"
    fi
}
