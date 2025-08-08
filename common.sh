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
    
    read -p "是否使用系统代理? (y/N): " use_system_proxy
    read -p "是否实时解密MP4分片? (y/N): " real_time_decrypt
    read -p "是否二进制合并? (y/N): " binary_merge
    
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
    
    [[ "$use_system_proxy" == "y" || "$use_system_proxy" == "Y" ]] && cmd+=" --use-system-proxy"
    [[ "$real_time_decrypt" == "y" || "$real_time_decrypt" == "Y" ]] && cmd+=" --mp4-real-time-decryption"
    [[ "$binary_merge" == "y" || "$binary_merge" == "Y" ]] && cmd+=" --binary-merge"
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始下载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始自定义下载: $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}下载完成!${RESET}"
            log "INFO" "自定义下载完成: $filename"
        else
            echo -e "${RED}下载失败!${RESET}"
            log "ERROR" "自定义下载失败，退出码: $exit_code"
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
    
    echo -e "${YELLOW}解密设置:${RESET}"
    echo ""
    
    read -p "密钥 (格式: KID:KEY 或直接输入KEY): " key
    read -p "IV (留空自动检测): " iv
    read -p "密钥文件路径 (留空跳过): " key_text_file
    
    echo -e "${YELLOW}解密引擎:${RESET}"
    echo "1) MP4DECRYPT (默认)"
    echo "2) FFMPEG"
    echo "3) SHAKA_PACKAGER"
    read -p "请选择解密引擎 (1-3, 默认1): " decryption_engine_choice
    
    local decryption_engine="MP4DECRYPT"
    case $decryption_engine_choice in
        2) decryption_engine="FFMPEG" ;;
        3) decryption_engine="SHAKA_PACKAGER" ;;
    esac
    
    read -p "解密工具路径 (留空使用默认): " decryption_binary_path
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    cmd+=" --del-after-done"
    
    if [[ -n "$key" ]]; then
        cmd+=" --key $key"
    fi
    
    if [[ -n "$iv" ]]; then
        cmd+=" --custom-hls-iv $iv"
    fi
    
    if [[ -n "$key_text_file" ]]; then
        cmd+=" --key-text-file \"$key_text_file\""
    fi
    
    cmd+=" --decryption-engine $decryption_engine"
    
    if [[ -n "$decryption_binary_path" ]]; then
        cmd+=" --decryption-binary-path \"$decryption_binary_path\""
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
    
    echo -e "${YELLOW}分片范围设置:${RESET}"
    echo ""
    
    read -p "起始分片 (从0开始): " start_segment
    read -p "结束分片 (留空下载到结尾): " end_segment
    read -p "自定义范围 (留空使用上面的设置): " custom_range
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    
    if [[ -n "$custom_range" ]]; then
        cmd+=" --custom-range $custom_range"
    else
        if [[ -n "$start_segment" ]]; then
            cmd+=" --segment-start $start_segment"
        fi
        
        if [[ -n "$end_segment" ]]; then
            cmd+=" --segment-end $end_segment"
        fi
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
            echo -e "${GREEN}部分分片下载完成!${RESET}"
            log "INFO" "部分分片下载完成: $filename"
        else
            echo -e "${RED}部分分片下载失败!${RESET}"
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
live_record_advanced() {
    echo -e "${CYAN}=== 直播录制高级设置 ===${RESET}"
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
    
    echo -e "${YELLOW}录制设置:${RESET}"
    echo ""
    
    read -p "录制时长限制 (格式: HH:mm:ss, 留空无限制): " record_limit
    read -p "录制等待时间(秒): " wait_time
    read -p "首次获取分片数量 (默认: 16): " take_count
    
    echo -e "${YELLOW}合并选项:${RESET}"
    read -p "实时合并? (y/N): " real_time_merge
    read -p "保留分片? (Y/n): " keep_segments
    read -p "通过管道+ffmpeg实时混流到TS文件? (y/N): " pipe_mux
    
    echo -e "${YELLOW}其他选项:${RESET}"
    read -p "以点播方式下载直播流? (y/N): " perform_as_vod
    read -p "通过读取音频文件的起始时间修正VTT字幕? (y/N): " fix_vtt_by_audio
    
    # 构建命令
    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --live-recording"
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    
    if [[ "$AutoSelect" == "true" ]]; then
        cmd+=" --auto-select"
    fi
    
    if [[ -n "$record_limit" ]]; then
        cmd+=" --live-record-limit $record_limit"
    fi
    
    if [[ -n "$wait_time" ]]; then
        cmd+=" --live-wait-time $wait_time"
    fi
    
    if [[ -n "$take_count" ]]; then
        cmd+=" --live-take-count $take_count"
    fi
    
    [[ "$real_time_merge" == "y" || "$real_time_merge" == "Y" ]] && cmd+=" --live-real-time-merge"
    [[ "$keep_segments" != "n" && "$keep_segments" != "N" ]] && cmd+=" --live-keep-segments"
    [[ "$pipe_mux" == "y" || "$pipe_mux" == "Y" ]] && cmd+=" --live-pipe-mux"
    [[ "$perform_as_vod" == "y" || "$perform_as_vod" == "Y" ]] && cmd+=" --live-perform-as-vod"
    [[ "$fix_vtt_by_audio" == "y" || "$fix_vtt_by_audio" == "Y" ]] && cmd+=" --live-fix-vtt-by-audio"
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    read -p "确认开始直播录制? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        log "INFO" "开始直播录制(高级): $link"
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}直播录制完成!${RESET}"
            log "INFO" "直播录制完成: $filename"
        else
            echo -e "${RED}直播录制失败!${RESET}"
            log "ERROR" "直播录制失败，退出码: $exit_code"
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

# 网络诊断工具
network_diagnosis() {
    echo -e "${CYAN}=== 网络诊断工具 ===${RESET}"
    echo ""
    
    read -p "请输入要诊断的URL: " url
    if [[ -z "$url" ]]; then
        echo -e "${RED}URL不能为空${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}正在诊断: $url${RESET}"
    echo ""
    
    # 检查URL是否可访问
    echo -e "${YELLOW}1. 检查URL可访问性...${RESET}"
    if command -v curl >/dev/null 2>&1; then
        local response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url")
        if [[ "$response_code" =~ ^2[0-9][0-9]$ ]]; then
            echo -e "${GREEN}  ✓ URL可访问 (HTTP $response_code)${RESET}"
        elif [[ "$response_code" =~ ^4[0-9][0-9]$ ]]; then
            echo -e "${RED}  ✗ 客户端错误 (HTTP $response_code)${RESET}"
        elif [[ "$response_code" =~ ^5[0-9][0-9]$ ]]; then
            echo -e "${RED}  ✗ 服务器错误 (HTTP $response_code)${RESET}"
        else
            echo -e "${RED}  ✗ 无法连接 ($response_code)${RESET}"
        fi
    else
        echo -e "${RED}  ✗ 未找到curl命令${RESET}"
    fi
    
    # 检查m3u8文件内容
    echo -e "${YELLOW}2. 检查m3u8文件内容...${RESET}"
    if command -v curl >/dev/null 2>&1; then
        local head_content=$(curl -s --connect-timeout 10 "$url" | head -20)
        if echo "$head_content" | grep -q "#EXTM3U"; then
            echo -e "${GREEN}  ✓ 检测到有效的m3u8文件${RESET}"
        else
            echo -e "${RED}  ✗ 未检测到有效的m3u8文件${RESET}"
            echo -e "${BLUE}  文件前20行内容:${RESET}"
            echo "$head_content"
        fi
    fi
    
    # DNS解析检查
    echo -e "${YELLOW}3. DNS解析检查...${RESET}"
    local domain=$(echo "$url" | sed -E 's|^https?://([^/]+).*|\1|')
    if command -v nslookup >/dev/null 2>&1; then
        if nslookup "$domain" >/dev/null 2>&1; then
            echo -e "${GREEN}  ✓ DNS解析成功: $domain${RESET}"
        else
            echo -e "${RED}  ✗ DNS解析失败: $domain${RESET}"
        fi
    else
        echo -e "${YELLOW}  - 未找到nslookup命令${RESET}"
    fi
    
    echo ""
    echo -e "${GREEN}网络诊断完成${RESET}"
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
            7) live_record_advanced ;;
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
