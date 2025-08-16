#!/bin/bash

# =============================================================================
# 下载模块
# =============================================================================

# 构建通用下载命令
build_download_command() {
    local link="$1"
    local filename="$2"
    local type="$3" # "single", "batch", "live"

    local cmd="$REfile \"$link\" --save-name \"$filename\""
    cmd+=" --thread-count $ThreadCount"
    cmd+=" --download-retry-count $RetryCount"
    cmd+=" --http-request-timeout $Timeout"
    cmd+=" --ffmpeg-binary-path \"$ffmpeg\""
    cmd+=" --tmp-dir \"$TempDir\""
    cmd+=" --save-dir \"$SaveDir\""
    cmd+=" --ui-language $Language"
    cmd+=" --log-level $LogLevel"
    cmd+=" --force-ansi-console"
     # 通用可选参数
     [[ "$AutoSelect" == "true" ]] && cmd+=" --auto-select"
    [[ "$ConcurrentDownload" == "true" ]] && cmd+=" -mt"
    [[ "$RealTimeDecryption" == "true" ]] && cmd+=" --mp4-real-time-decryption"
    [[ "$CheckSegments" == "true" ]] && cmd+=" --check-segments-count"
    [[ "$DeleteAfterDone" == "true" ]] && cmd+=" --del-after-done"
    [[ "$WriteMetaJson" == "true" ]] && cmd+=" --write-meta-json"
    [[ "$AppendUrlParams" == "true" ]] && cmd+=" --append-url-params"

    # 直播录制专用参数
    if [[ "$type" == "live" ]]; then
        [[ "$BinaryMerge" == "true" ]] && cmd+=" --binary-merge"
        [[ "$NoDateInfo" == "true" ]] && cmd+=" --no-date-info"
        [[ "$UseFFmpegConcatDemuxer" == "true" ]] && cmd+=" --use-ffmpeg-concat-demuxer"
        [[ "$SubOnly" == "true" ]] && cmd+=" --sub-only"
        [[ "$SubFormat" != "" ]] && cmd+=" --sub-format $SubFormat"
        [[ "$AutoSubtitleFix" == "true" ]] && cmd+=" --auto-subtitle-fix"
        [[ "$MaxSpeed" != "" ]] && cmd+=" -R $MaxSpeed"
        [[ "$CustomRange" != "" ]] && cmd+=" --custom-range $CustomRange"
        [[ "$LivePerformAsVod" == "true" ]] && cmd+=" --live-perform-as-vod"
        [[ "$LiveRealTimeMerge" == "true" ]] && cmd+=" --live-real-time-merge"
        [[ "$LiveKeepSegments" == "true" ]] && cmd+=" --live-keep-segments"
        [[ "$LivePipeMux" == "true" ]] && cmd+=" --live-pipe-mux"
    fi

    echo "$cmd"
}

# 单个视频下载
single_download() {
    show_title "单个视频下载"
    
    local link=$(input_box "请输入视频链接")
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    local filename=$(input_box "请输入保存文件名" "video_$(date +%Y%m%d_%H%M%S)")
    
    # 确保目录存在
    create_directories
    
    # 构建命令
    local cmd=$(build_download_command "$link" "$filename" "single")
    
    echo ""
    echo -e "${PURPLE}执行命令:${RESET}"
    echo "$cmd"
    echo ""
    
    if confirm_action "确认开始下载?"; then
        log "INFO" "开始下载: $link"
        # 使用更详细的输出模式来帮助诊断问题
        eval "$cmd"
        local exit_code=$?
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}下载完成!${RESET}"
            log "INFO" "下载完成: $filename"
        else
            handle_download_error "$exit_code"
        fi
    fi
}
# 信号处理函数
cleanup_and_exit() {
    echo -e "\n${RED}批量下载被用户中断...${RESET}"
    log "WARN" "批量下载被用户中断"
    
    # 更新失败计数
    fail_count=$((fail_count + 1))
    
    # 显示最终统计
    show_batch_summary
    
    # 退出脚本
    exit 130 # 130 是SIGINT的标准退出码
}

# 显示批量下载摘要
show_batch_summary() {
    echo ""
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BLUE}  批量下载任务报告${RESET}"
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${GREEN}成功: $success_count${RESET}"
    echo -e "${RED}失败: $fail_count${RESET}"
    echo -e "${BLUE}总计: $line_count${RESET}"
    
    if (( line_count > 0 )); then
        local percentage=$(( success_count * 100 / line_count ))
        echo -e "${BLUE}完成率: ${percentage}%${RESET}"
    fi
    
    log "INFO" "批量下载任务完成 - 成功: $success_count, 失败: $fail_count, 总计: $line_count"
}

# 批量下载
batch_download() {
    show_title "批量下载"
    
    local file_path=$(input_box "请输入链接文件路径")
    if [[ -z "$file_path" ]]; then
        echo -e "${RED}文件路径不能为空${RESET}"
        return 1
    fi
    
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}文件不存在: $file_path${RESET}"
        return 1
    fi
    
    # 设置信号陷阱
    trap 'cleanup_and_exit' SIGINT
    
    # 开始批量下载任务
    echo -e "${BLUE}开始批量下载任务...${RESET}"
    echo -e "${BLUE}线程数: $ThreadCount${RESET}"
    echo -e "${BLUE}超时时间: $Timeout 秒${RESET}"
    echo ""
    
    local success_count=0
    local fail_count=0
    local current=0
    
    # 计算总链接数（非空行）
    local line_count=$(grep -c '[^[:space:]]' "$file_path" 2>/dev/null || echo 0)
    echo -e "${BLUE}检测到 $line_count 个链接${RESET}"
    
    if ! confirm_action "确认开始批量下载?"; then
        return 1
    fi
    
    # 使用while循环读取文件，确保兼容性
    while IFS= read -r link || [[ -n "$link" ]]; do
        # 跳过空行
        if [[ -z "$link" ]]; then
            continue
        fi
        
        # 解析带名称格式的链接
        local actual_link="$link"
        local custom_name=""
        if [[ "$link" == *'$'* ]]; then
            custom_name="${link%%\$*}"  # 使用\$转义$
            actual_link="${link#*\$}"   # 使用\$转义$
        fi
        
        current=$((current + 1))
        echo ""
        echo -e "${CYAN}处理第 $current/$line_count 个链接${RESET}"
        echo -e "${BLUE}链接: $actual_link${RESET}"
        
        local filename="batch_$(date +%Y%m%d_%H%M%S)_$current"
        # 如果有自定义名称，则使用自定义名称
        if [[ -n "$custom_name" ]]; then
            filename="$custom_name"
        fi
        
        # 清理文件名中的特殊字符
        filename=$(echo "$filename" | sed 's/[<>:"/\\|?*]/_/g' | sed 's/[$]/_/g')
        
        local cmd=$(build_download_command "$actual_link" "$filename" "batch")
        
        log "INFO" "批量下载: $actual_link"
        echo -e "${BLUE}执行命令: $cmd${RESET}"
        
        # 清理临时目录，防止文件句柄过多
        cleanup_empty_temp_dirs
        
        # 执行命令，直接显示输出，不使用后台执行
        echo -e "${BLUE}下载进度:${RESET}"
        eval "$cmd"
        local exit_code=$?
        
        # 下载完成后再次清理临时文件
        cleanup_empty_temp_dirs
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}✓ 下载成功${RESET}"
            success_count=$((success_count + 1))
            log "INFO" "批量下载成功: $filename"
        else
            # 即使被中断，也应视为失败
            handle_download_error "$exit_code"
            fail_count=$((fail_count + 1))
        fi
        
    done < "$file_path"
    
    # 显示最终统计信息
    show_batch_summary
    
    # 清理临时目录
    cleanup_empty_temp_dirs
    
    # 重置信号陷阱
    trap - SIGINT
}

# 直播录制
live_recording() {
    show_title "直播录制"
    
    local link=$(input_box "请输入直播链接")
    if [[ -z "$link" ]]; then
        echo -e "${RED}链接不能为空${RESET}"
        return 1
    fi
    
    local duration=$(input_box "请输入录制时长(分钟)" "60")
    local filename=$(input_box "请输入保存文件名" "live_$(date +%Y%m%d_%H%M%S)")
    
    echo -e "${BLUE}开始录制直播，时长: ${duration}分钟${RESET}"
    
    if confirm_action "确认开始录制?"; then
        log "INFO" "开始录制直播: $link"
        
        # 构建基础命令
        local cmd=$(build_download_command "$link" "$filename" "live")
        
        # 如果设置了录制时长限制
        if [[ "$duration" -gt 0 ]]; then
            local formatted_duration=$(printf "%02d:00:00" "$duration")
            cmd+=" --live-record-limit $formatted_duration"
        fi
        
        # 执行命令
        eval "$cmd"
        local exit_code=$?
        
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}录制完成${RESET}"
            log "INFO" "直播录制完成: $filename"
        else
            handle_download_error "$exit_code"
        fi
        
        # 清理空的临时目录
        cleanup_empty_temp_dirs
    fi
}

# 处理下载错误
handle_download_error() {
    local exit_code="$1"
    log "ERROR" "下载失败，退出码: $exit_code"
    echo -e "${RED}下载失败! (退出码: $exit_code)${RESET}"
    echo -e "${YELLOW}可能的原因与解决方案:${RESET}"
    
    case "$exit_code" in
        1)
            echo -e "${YELLOW}- 链接无效或已过期 (例如 404 Not Found)。${RESET}"
            echo -e "${YELLOW}- 请在浏览器中检查链接是否可以正常访问。${RESET}"
            ;;
        2)
            echo -e "${YELLOW}- 网络问题或SSL/TLS证书验证失败。${RESET}"
            echo -e "${YELLOW}- 请检查您的网络连接和防火墙设置。${RESET}"
            ;;
        3)
            echo -e "${YELLOW}- FFmpeg 相关错误，可能是合并或转码失败。${RESET}"
            echo -e "${YELLOW}- 请确保 ffmpeg 程序完整且有执行权限。${RESET}"
            ;;
        5)
            echo -e "${YELLOW}- 解密错误，可能是密钥不正确或无法获取。${RESET}"
            echo -e "${YELLOW}- 请检查视频是否受DRM保护。${RESET}"
            ;;
        *)
            echo -e "${YELLOW}- 未知错误。${RESET}"
            echo -e "${YELLOW}- 您可以尝试降低线程数或增加超时时间。${RESET}"
            echo -e "${YELLOW}- 查看日志文件 ($LOG_FILE) 获取更详细的信息。${RESET}"
            ;;
    esac
}