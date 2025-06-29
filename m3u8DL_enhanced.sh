#!/bin/bash

# =============================================================================
# N_m3u8DL-RE 下载管理器
# 版本: 2.0.0
# 日期: 2024-12-01
# =============================================================================

# 颜色代码定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_FILE="$SCRIPT_DIR/m3u8dl.log"
LOCK_FILE="$SCRIPT_DIR/m3u8dl.lock"
REfile="$SCRIPT_DIR/N_m3u8DL-RE"
ffmpeg="$SCRIPT_DIR/ffmpeg"

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
    if [[ ! -f "$REfile" ]]; then
        echo -e "${RED}错误: N_m3u8DL-RE 程序不存在${RESET}"
        echo -e "${YELLOW}请运行 ./install.sh 安装程序${RESET}"
        exit 1
    fi
    
    if [[ ! -f "$ffmpeg" ]]; then
        echo -e "${RED}错误: ffmpeg 程序不存在${RESET}"
        echo -e "${YELLOW}请运行 ./install.sh 安装程序${RESET}"
        exit 1
    fi
    
    chmod +x "$REfile" 2>/dev/null
    chmod +x "$ffmpeg" 2>/dev/null
}

# 创建目录
create_directories() {
    mkdir -p "$SaveDir"
    mkdir -p "$TempDir"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# 显示主菜单
show_menu() {
    clear
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo -e "${CYAN}${BOLD}    N_m3u8DL-RE 下载管理器${RESET}"
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo ""
    echo -e "${WHITE}1. 单个视频下载${RESET}"
    echo -e "${WHITE}2. 批量下载${RESET}"
    echo -e "${WHITE}3. 直播录制${RESET}"
    echo -e "${WHITE}4. 高级功能${RESET}"
    echo -e "${WHITE}5. 设置${RESET}"
    echo -e "${WHITE}6. 自动更新${RESET}"
    echo -e "${WHITE}0. 退出${RESET}"
    echo ""
}

# 单个视频下载
single_download() {
    echo -e "${CYAN}=== 单个视频下载 ===${RESET}"
    echo ""
    
    read -p "请输入视频链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="video_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --thread-count $ThreadCount"
    cmd+=" --download-retry-count $RetryCount"
    cmd+=" --http-request-timeout $Timeout"
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    
    # 可选参数
    [[ "$AutoSelect" == "true" ]] && cmd+=" --auto-select"
    [[ "$ConcurrentDownload" == "true" ]] && cmd+=" -mt"
    [[ "$RealTimeDecryption" == "true" ]] && cmd+=" --mp4-real-time-decryption"
    [[ "$CheckSegments" == "true" ]] && cmd+=" --check-segments-count"
    [[ "$DeleteAfterDone" == "true" ]] && cmd+=" --del-after-done"
    [[ "$WriteMetaJson" == "true" ]] && cmd+=" --write-meta-json"
    [[ "$AppendUrlParams" == "true" ]] && cmd+=" --append-url-params"
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始下载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始下载: $link"
        eval "$cmd"
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}下载完成!${RESET}"
            log "INFO" "下载完成: $filename"
        else
            echo -e "${RED}下载失败!${RESET}"
            log "ERROR" "下载失败，退出码: $exit_code"
        fi
    fi
}

# 批量下载
batch_download() {
    echo -e "${CYAN}=== 批量下载 ===${RESET}"
    echo ""
    
    read -p "请输入链接文件路径: " file_path
    if [[ -z "$file_path" ]]; then
        echo -e "${RED}文件路径不能为空${RESET}"
        return 1
    fi
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}文件不存在: $file_path${RESET}"
        return 1
    fi
    
    read -p "请输入保存目录名: " dir_name
    if [[ -z "$dir_name" ]]; then
        dir_name="batch_$(date +%Y%m%d_%H%M%S)"
    fi
    
    local batch_dir="$SaveDir/$dir_name"
    mkdir -p "$batch_dir"
    
    echo ""
    echo -e "${BLUE}开始批量下载...${RESET}"
    echo -e "保存目录: $batch_dir"
    echo ""
    
    local count=0
    local success=0
    local failed=0
    
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            count=$((count + 1))
            echo -e "${BLUE}[$count] 下载: $line${RESET}"
            
            local filename="video_${count}"
            local cmd="$REfile \"$line\" --save-name \"$filename\""
            cmd+=" --thread-count $ThreadCount"
            cmd+=" --download-retry-count $RetryCount"
            cmd+=" --http-request-timeout $Timeout"
            cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
            cmd+=" --tmp-dir \"$TempDir\""
            cmd+=" --save-dir \"$batch_dir\""
            cmd+=" --ui-language $Language"
            cmd+=" --log-level $LogLevel"
            
            [[ "$AutoSelect" == "true" ]] && cmd+=" --auto-select"
            [[ "$ConcurrentDownload" == "true" ]] && cmd+=" -mt"
            [[ "$RealTimeDecryption" == "true" ]] && cmd+=" --mp4-real-time-decryption"
            [[ "$CheckSegments" == "true" ]] && cmd+=" --check-segments-count"
            [[ "$DeleteAfterDone" == "true" ]] && cmd+=" --del-after-done"
            [[ "$WriteMetaJson" == "true" ]] && cmd+=" --write-meta-json"
            [[ "$AppendUrlParams" == "true" ]] && cmd+=" --append-url-params"
            
            if eval "$cmd"; then
                echo -e "${GREEN}✓ 成功${RESET}"
                success=$((success + 1))
            else
                echo -e "${RED}✗ 失败${RESET}"
                failed=$((failed + 1))
            fi
            echo ""
        fi
    done < "$file_path"
    
    echo -e "${CYAN}批量下载完成${RESET}"
    echo -e "总计: $count, 成功: $success, 失败: $failed"
    log "INFO" "批量下载完成: 总计$count, 成功$success, 失败$failed"
}

# 直播录制
live_recording() {
    echo -e "${CYAN}=== 直播录制 ===${RESET}"
    echo ""
    
    read -p "请输入直播链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="live_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "录制时长(分钟, 0为无限): " duration
    if [[ -z "$duration" ]]; then
        duration=0
    fi
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --thread-count $ThreadCount"
    cmd+=" --download-retry-count $RetryCount"
    cmd+=" --http-request-timeout $Timeout"
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    cmd+=" --live-recording"
    
    # 可选参数
    [[ "$AutoSelect" == "true" ]] && cmd+=" --auto-select"
    [[ "$ConcurrentDownload" == "true" ]] && cmd+=" -mt"
    [[ "$RealTimeDecryption" == "true" ]] && cmd+=" --mp4-real-time-decryption"
    [[ "$CheckSegments" == "true" ]] && cmd+=" --check-segments-count"
    [[ "$DeleteAfterDone" == "true" ]] && cmd+=" --del-after-done"
    [[ "$WriteMetaJson" == "true" ]] && cmd+=" --write-meta-json"
    [[ "$AppendUrlParams" == "true" ]] && cmd+=" --append-url-params"
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始录制? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始直播录制: $link"
        
        if [[ "$duration" -gt 0 ]]; then
            echo -e "${YELLOW}将在 $duration 分钟后自动停止录制${RESET}"
            eval "$cmd" &
            local pid=$!
            sleep $((duration * 60))
            kill $pid 2>/dev/null
            echo -e "${GREEN}录制完成!${RESET}"
        else
            eval "$cmd"
        fi
        
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}录制完成!${RESET}"
            log "INFO" "直播录制完成: $filename"
        else
            echo -e "${RED}录制失败!${RESET}"
            log "ERROR" "直播录制失败，退出码: $exit_code"
        fi
    fi
}

# 高级功能
advanced_features() {
    if [[ -f "advanced.sh" ]]; then
        chmod +x advanced.sh
        ./advanced.sh
    else
        echo -e "${RED}高级功能脚本不存在${RESET}"
    fi
}

# 设置
settings() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}=== 设置 ===${RESET}"
        echo ""
        echo -e "${WHITE}1. 线程数: ${GREEN}$ThreadCount${RESET}"
        echo -e "${WHITE}2. 重试次数: ${GREEN}$RetryCount${RESET}"
        echo -e "${WHITE}3. 超时时间: ${GREEN}$Timeout${RESET}"
        echo -e "${WHITE}4. 保存目录: ${GREEN}$SaveDir${RESET}"
        echo -e "${WHITE}5. 临时目录: ${GREEN}$TempDir${RESET}"
        echo -e "${WHITE}6. 语言: ${GREEN}$Language${RESET}"
        echo -e "${WHITE}7. 日志级别: ${GREEN}$LogLevel${RESET}"
        echo -e "${WHITE}8. 自动选择: ${GREEN}$AutoSelect${RESET}"
        echo -e "${WHITE}9. 并发下载: ${GREEN}$ConcurrentDownload${RESET}"
        echo -e "${WHITE}10. 实时解密: ${GREEN}$RealTimeDecryption${RESET}"
        echo -e "${WHITE}11. 检查分片: ${GREEN}$CheckSegments${RESET}"
        echo -e "${WHITE}12. 完成后删除: ${GREEN}$DeleteAfterDone${RESET}"
        echo -e "${WHITE}13. 写入元数据: ${GREEN}$WriteMetaJson${RESET}"
        echo -e "${WHITE}14. 追加URL参数: ${GREEN}$AppendUrlParams${RESET}"
        echo -e "${WHITE}0. 返回主菜单${RESET}"
        echo ""
        
        read -p "请选择要修改的设置 (0-14): " choice
        
        case $choice in
            1) read -p "请输入线程数: " ThreadCount ;;
            2) read -p "请输入重试次数: " RetryCount ;;
            3) read -p "请输入超时时间: " Timeout ;;
            4) read -p "请输入保存目录: " SaveDir ;;
            5) read -p "请输入临时目录: " TempDir ;;
            6) read -p "请输入语言 (zh-CN/en-US): " Language ;;
            7) read -p "请输入日志级别 (INFO/DEBUG/WARN/ERROR): " LogLevel ;;
            8) read -p "自动选择 (true/false): " AutoSelect ;;
            9) read -p "并发下载 (true/false): " ConcurrentDownload ;;
            10) read -p "实时解密 (true/false): " RealTimeDecryption ;;
            11) read -p "检查分片 (true/false): " CheckSegments ;;
            12) read -p "完成后删除 (true/false): " DeleteAfterDone ;;
            13) read -p "写入元数据 (true/false): " WriteMetaJson ;;
            14) read -p "追加URL参数 (true/false): " AppendUrlParams ;;
            0) 
                save_config
                return 0
                ;;
            *) echo -e "${RED}无效选择${RESET}" ;;
        esac
        
        save_config
        echo -e "${GREEN}设置已保存${RESET}"
        sleep 1
    done
}

# 自动更新
auto_update() {
    if [[ -f "auto_update.sh" ]]; then
        chmod +x auto_update.sh
        ./auto_update.sh
    else
        echo -e "${RED}自动更新脚本不存在${RESET}"
    fi
}

# 主循环
main() {
    # 初始化
    check_programs
    create_directories
    load_config
    
    while true; do
        show_menu
        read -p "请选择操作 (0-6): " choice
        
        case $choice in
            1) single_download ;;
            2) batch_download ;;
            3) live_recording ;;
            4) advanced_features ;;
            5) settings ;;
            6) auto_update ;;
            0) 
                echo -e "${GREEN}退出程序${RESET}"
                exit 0
                ;;
            *) 
                echo -e "${RED}无效选择，请重新输入${RESET}"
                sleep 1
                ;;
        esac
        
        echo ""
        read -p "按回车键返回主菜单..."
    done
}

# 启动程序
main "$@" 