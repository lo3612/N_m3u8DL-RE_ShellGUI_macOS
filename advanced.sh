#!/bin/bash

# 高级功能

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

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_FILE="$SCRIPT_DIR/m3u8dl.log"

# 加载配置
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo -e "${RED}配置文件不存在，请先运行主程序${RESET}"
    exit 1
fi

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

# 显示高级菜单
show_advanced_menu() {
    clear
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo -e "${CYAN}${BOLD}    N_m3u8DL-RE 高级功能${RESET}"
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo ""
    echo -e "${WHITE}1. 自定义参数下载${RESET}"
    echo -e "${WHITE}2. 字幕提取${RESET}"
    echo -e "${WHITE}3. 音视频分离下载${RESET}"
    echo -e "${WHITE}4. 加密视频解密${RESET}"
    echo -e "${WHITE}5. 部分分片下载${RESET}"
    echo -e "${WHITE}6. 外部媒体混流${RESET}"
    echo -e "${WHITE}7. 直播录制高级设置${RESET}"
    echo -e "${WHITE}8. 批量任务管理${RESET}"
    echo -e "${WHITE}9. 性能监控${RESET}"
    echo -e "${WHITE}0. 返回主程序${RESET}"
    echo ""
}

# 自定义参数下载
custom_download() {
    echo -e "${CYAN}=== 自定义参数下载 ===${RESET}"
    echo ""
    
    read -p "请输入视频链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="custom_$(date +%Y%m%d_%H%M%S)"
    fi
    
    echo ""
    echo -e "${YELLOW}自定义参数设置:${RESET}"
    echo ""
    
    read -p "线程数 (默认: $ThreadCount): " custom_threads
    custom_threads=${custom_threads:-$ThreadCount}
    
    read -p "重试次数 (默认: $RetryCount): " custom_retries
    custom_retries=${custom_retries:-$RetryCount}
    
    read -p "超时时间(秒) (默认: $Timeout): " custom_timeout
    custom_timeout=${custom_timeout:-$Timeout}
    
    read -p "限速 (如: 10M, 100K, 留空无限制): " custom_speed
    
    read -p "代理 (如: http://127.0.0.1:8888, 留空无代理): " custom_proxy
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --thread-count $custom_threads"
    cmd+=" --download-retry-count $custom_retries"
    cmd+=" --http-request-timeout $custom_timeout"
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
    
    # 自定义参数
    [[ -n "$custom_speed" ]] && cmd+=" -R $custom_speed"
    if [[ -n "$custom_proxy" ]]; then
        if [[ "$custom_proxy" == "system" ]]; then
            cmd+=" --use-system-proxy"
        else
            cmd+=" --custom-proxy $custom_proxy"
        fi
    fi
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始下载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始自定义参数下载: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}下载完成!${RESET}"
            log "INFO" "自定义参数下载完成: $filename"
        else
            echo -e "${RED}下载失败!${RESET}"
            log "ERROR" "自定义参数下载失败，退出码: $exit_code"
        fi
    fi
}

# 字幕提取
subtitle_extract() {
    echo -e "${CYAN}=== 字幕提取 ===${RESET}"
    echo ""
    
    read -p "请输入视频链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="subtitle_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "字幕格式 (SRT/VTT, 默认: SRT): " sub_format
    sub_format=${sub_format:-"SRT"}
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --sub-only"
    cmd+=" --sub-format $sub_format"
    cmd+=" --auto-subtitle-fix"
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    cmd+=" --del-after-done"
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始提取字幕? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始字幕提取: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}字幕提取完成!${RESET}"
            log "INFO" "字幕提取完成: $filename"
        else
            echo -e "${RED}字幕提取失败!${RESET}"
            log "ERROR" "字幕提取失败，退出码: $exit_code"
        fi
    fi
}

# 音视频分离下载
audio_video_separate() {
    echo -e "${CYAN}=== 音视频分离下载 ===${RESET}"
    echo ""
    
    read -p "请输入视频链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="separate_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "下载音频 (y/N): " download_audio
    read -p "下载视频 (y/N): " download_video
    
    if [[ "$download_audio" != "y" && "$download_video" != "y" ]]; then
        echo -e "${RED}至少需要选择下载音频或视频${RESET}"
        return 1
    fi
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    
    if [[ "$download_audio" == "y" ]]; then
        cmd+=" --audio-only"
    fi
    
    if [[ "$download_video" == "y" ]]; then
        cmd+=" --video-only"
    fi
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始分离下载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始音视频分离下载: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}分离下载完成!${RESET}"
            log "INFO" "音视频分离下载完成: $filename"
        else
            echo -e "${RED}分离下载失败!${RESET}"
            log "ERROR" "音视频分离下载失败，退出码: $exit_code"
        fi
    fi
}

# 加密视频解密
decrypt_video() {
    echo -e "${CYAN}=== 加密视频解密 ===${RESET}"
    echo ""
    
    read -p "请输入视频链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="decrypt_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "密钥 (留空自动检测): " key
    read -p "IV (留空自动检测): " iv
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    cmd+=" --enable-del-after-done"
    
    if [[ -n "$key" ]]; then
        cmd+=" --key $key"
    fi
    
    if [[ -n "$iv" ]]; then
        cmd+=" --iv $iv"
    fi
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始解密下载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始加密视频解密: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}解密下载完成!${RESET}"
            log "INFO" "加密视频解密完成: $filename"
        else
            echo -e "${RED}解密下载失败!${RESET}"
            log "ERROR" "加密视频解密失败，退出码: $exit_code"
        fi
    fi
}

# 部分分片下载
partial_download() {
    echo -e "${CYAN}=== 部分分片下载 ===${RESET}"
    echo ""
    
    read -p "请输入视频链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="partial_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "起始分片 (从0开始): " start_segment
    read -p "结束分片 (留空下载到结尾): " end_segment
    
    if [[ -z "$start_segment" ]]; then
        echo -e "${RED}起始分片不能为空${RESET}"
        return 1
    fi
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    cmd+=" --segment-start $start_segment"
    
    if [[ -n "$end_segment" ]]; then
        cmd+=" --segment-end $end_segment"
    fi
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始部分下载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始部分分片下载: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}部分下载完成!${RESET}"
            log "INFO" "部分分片下载完成: $filename"
        else
            echo -e "${RED}部分下载失败!${RESET}"
            log "ERROR" "部分分片下载失败，退出码: $exit_code"
        fi
    fi
}

# 外部媒体混流
external_mux() {
    echo -e "${CYAN}=== 外部媒体混流 ===${RESET}"
    echo ""
    
    read -p "请输入视频链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="mux_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "外部音频文件路径: " audio_file
    read -p "外部字幕文件路径: " subtitle_file
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    
    if [[ -n "$audio_file" ]]; then
        cmd+=" --external-audio \"$audio_file\""
    fi
    
    if [[ -n "$subtitle_file" ]]; then
        cmd+=" --external-subtitle \"$subtitle_file\""
    fi
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始混流下载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始外部媒体混流: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}混流下载完成!${RESET}"
            log "INFO" "外部媒体混流完成: $filename"
        else
            echo -e "${RED}混流下载失败!${RESET}"
            log "ERROR" "外部媒体混流失败，退出码: $exit_code"
        fi
    fi
}

# 直播录制高级设置
advanced_live_recording() {
    echo -e "${CYAN}=== 直播录制高级设置 ===${RESET}"
    echo ""
    
    read -p "请输入直播链接: " link
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    read -p "请输入保存文件名: " filename
    if [[ -z "$filename" ]]; then
        filename="live_advanced_$(date +%Y%m%d_%H%M%S)"
    fi
    
    read -p "录制时长限制 (HH:mm:ss, 留空无限制): " record_limit
    read -p "保持分片 (y/N): " keep_segments
    read -p "修复VTT字幕 (y/N): " fix_vtt
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    cmd+=" --live-recording"
    
    if [[ -n "$record_limit" ]]; then
        cmd+=" --live-record-limit $record_limit"
    fi
    
    if [[ "$keep_segments" == "y" ]]; then
        cmd+=" --live-keep-segments"
    fi
    
    if [[ "$fix_vtt" == "y" ]]; then
        cmd+=" --live-fix-vtt-by-audio"
    fi
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始高级录制? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始直播录制高级设置: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}高级录制完成!${RESET}"
            log "INFO" "直播录制高级设置完成: $filename"
        else
            echo -e "${RED}高级录制失败!${RESET}"
            log "ERROR" "直播录制高级设置失败，退出码: $exit_code"
        fi
    fi
}

# 批量任务管理
batch_task_management() {
    echo -e "${CYAN}=== 批量任务管理 ===${RESET}"
    echo ""
    
    echo -e "${WHITE}1. 创建批量任务${RESET}"
    echo -e "${WHITE}2. 查看任务状态${RESET}"
    echo -e "${WHITE}3. 暂停任务${RESET}"
    echo -e "${WHITE}4. 恢复任务${RESET}"
    echo -e "${WHITE}5. 删除任务${RESET}"
    echo -e "${WHITE}0. 返回${RESET}"
    echo ""
    
    read -p "请选择操作: " choice
    
    case $choice in
        1) create_batch_task ;;
        2) show_task_status ;;
        3) pause_task ;;
        4) resume_task ;;
        5) delete_task ;;
        0) return 0 ;;
        *) echo -e "${RED}无效选择${RESET}" ;;
    esac
}

# 创建批量任务
create_batch_task() {
    echo -e "${BLUE}创建批量任务...${RESET}"
    read -p "请输入任务名称: " task_name
    read -p "请输入链接文件路径: " link_file
    
    if [[ ! -f "$link_file" ]]; then
        echo -e "${RED}链接文件不存在${RESET}"
        return 1
    fi
    
    local task_dir="$SCRIPT_DIR/tasks/$task_name"
    mkdir -p "$task_dir"
    
    cp "$link_file" "$task_dir/links.txt"
    echo "$(date)" > "$task_dir/created.txt"
    echo "pending" > "$task_dir/status.txt"
    
    echo -e "${GREEN}批量任务创建成功: $task_name${RESET}"
}

# 查看任务状态
show_task_status() {
    echo -e "${BLUE}任务状态:${RESET}"
    local tasks_dir="$SCRIPT_DIR/tasks"
    
    if [[ ! -d "$tasks_dir" ]]; then
        echo -e "${YELLOW}暂无任务${RESET}"
        return 0
    fi
    
    for task_dir in "$tasks_dir"/*; do
        if [[ -d "$task_dir" ]]; then
            local task_name=$(basename "$task_dir")
            local status=""
            if [[ -f "$task_dir/status.txt" ]]; then
                status=$(cat "$task_dir/status.txt")
            fi
            echo -e "$task_name: $status"
        fi
    done
}

# 暂停任务
pause_task() {
    read -p "请输入任务名称: " task_name
    local task_dir="$SCRIPT_DIR/tasks/$task_name"
    
    if [[ ! -d "$task_dir" ]]; then
        echo -e "${RED}任务不存在${RESET}"
        return 1
    fi
    
    echo "paused" > "$task_dir/status.txt"
    echo -e "${GREEN}任务已暂停${RESET}"
}

# 恢复任务
resume_task() {
    read -p "请输入任务名称: " task_name
    local task_dir="$SCRIPT_DIR/tasks/$task_name"
    
    if [[ ! -d "$task_dir" ]]; then
        echo -e "${RED}任务不存在${RESET}"
        return 1
    fi
    
    echo "running" > "$task_dir/status.txt"
    echo -e "${GREEN}任务已恢复${RESET}"
}

# 删除任务
delete_task() {
    read -p "请输入任务名称: " task_name
    local task_dir="$SCRIPT_DIR/tasks/$task_name"
    
    if [[ ! -d "$task_dir" ]]; then
        echo -e "${RED}任务不存在${RESET}"
        return 1
    fi
    
    read -p "确认删除任务 $task_name? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -rf "$task_dir"
        echo -e "${GREEN}任务已删除${RESET}"
    fi
}

# 性能监控
performance_monitor() {
    echo -e "${CYAN}=== 性能监控 ===${RESET}"
    echo ""
    
    echo -e "${BLUE}系统资源使用情况:${RESET}"
    echo -e "CPU使用率: $(top -l 1 | grep "CPU usage" | awk '{print $3}' | cut -d'%' -f1)%"
    echo -e "内存使用率: $(top -l 1 | grep "PhysMem" | awk '{print $2}' | cut -d'%' -f1)%"
    echo -e "磁盘使用率: $(df -h . | tail -1 | awk '{print $5}' | cut -d'%' -f1)%"
    
    echo ""
    echo -e "${BLUE}网络连接:${RESET}"
    netstat -an | grep ESTABLISHED | wc -l | xargs echo "活跃连接数:"
    
    echo ""
    echo -e "${BLUE}进程信息:${RESET}"
    ps aux | grep -E "(N_m3u8DL-RE|ffmpeg)" | grep -v grep || echo "无相关进程运行"
}

# 主循环
main() {
    while true; do
        show_advanced_menu
        read -p "请选择操作 (0-9): " choice
        
        case $choice in
            1) custom_download ;;
            2) subtitle_extract ;;
            3) audio_video_separate ;;
            4) decrypt_video ;;
            5) partial_download ;;
            6) external_mux ;;
            7) advanced_live_recording ;;
            8) batch_task_management ;;
            9) performance_monitor ;;
            0) 
                echo -e "${GREEN}返回主程序${RESET}"
                exit 0
                ;;
            *) 
                echo -e "${RED}无效选择，请重新输入${RESET}"
                sleep 1
                ;;
        esac
        
        echo ""
        read -p "按回车键返回高级菜单..."
    done
}

# 启动程序
main "$@" 
