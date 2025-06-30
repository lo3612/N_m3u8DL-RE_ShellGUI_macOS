#!/bin/bash

# =============================================================================
# N_m3u8DL-RE 下载管理器
# 版本: 2.1.0
# 日期: 2025-6-30
# =============================================================================

# 引入公共函数库
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 程序路径
REfile="$SCRIPT_DIR/N_m3u8DL-RE"
ffmpeg="$SCRIPT_DIR/ffmpeg"

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# 初始化
init() {
    load_config
    check_programs
    create_directories
}

# 显示主菜单
show_main_menu() {
    clear
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo -e "${CYAN}${BOLD}  N_m3u8DL-RE 下载管理器${RESET}"
    echo -e "${CYAN}${BOLD}========================================${RESET}"
    echo ""
    echo -e "${WHITE}1. 单个视频下载${RESET}"
    echo -e "${WHITE}2. 批量下载${RESET}"
    echo -e "${WHITE}3. 直播录制${RESET}"
    echo -e "${WHITE}4. 高级功能${RESET}"
    echo -e "${WHITE}5. 设置${RESET}"
    echo -e "${WHITE}6. 自动更新${RESET}"
    echo -e "${WHITE}0. 退出程序${RESET}"
    echo ""
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
    
    if confirm_action "确认开始下载?"; then
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
    
    local line_count=$(wc -l < "$file_path")
    echo -e "${BLUE}检测到 $line_count 个链接${RESET}"
    
    if ! confirm_action "确认开始批量下载?"; then
        return 1
    fi
    
    local success_count=0
    local fail_count=0
    local current=0
    
    while IFS= read -r link; do
        current=$((current + 1))
        echo ""
        echo -e "${CYAN}处理第 $current/$line_count 个链接${RESET}"
        echo -e "${BLUE}链接: $link${RESET}"
        
        local filename="batch_$(date +%Y%m%d_%H%M%S)_$current"
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
        
        log "INFO" "批量下载: $link"
        eval "$cmd"
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✓ 下载成功${RESET}"
            success_count=$((success_count + 1))
            log "INFO" "批量下载成功: $filename"
        else
            echo -e "${RED}✗ 下载失败${RESET}"
            fail_count=$((fail_count + 1))
            log "ERROR" "批量下载失败: $link"
        fi
        
        show_progress "$current" "$line_count"
    done < "$file_path"
    
    echo ""
    echo -e "${GREEN}批量下载完成!${RESET}"
    echo -e "${BLUE}成功: $success_count, 失败: $fail_count${RESET}"
    log "INFO" "批量下载完成: 成功 $success_count, 失败 $fail_count"
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
        
        # 构建录制命令
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
        
        # 后台运行录制
        eval "$cmd" &
        local pid=$!
        
        echo -e "${GREEN}录制已开始，进程ID: $pid${RESET}"
        echo -e "${YELLOW}将在 ${duration} 分钟后自动停止${RESET}"
        
        # 等待指定时间后停止
        sleep $((duration * 60))
        
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo -e "${GREEN}录制已停止${RESET}"
            log "INFO" "直播录制完成: $filename"
        else
            echo -e "${YELLOW}录制进程已结束${RESET}"
        fi
    fi
}

# 高级功能
advanced_features() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}========================================${RESET}"
        echo -e "${CYAN}${BOLD}  高级功能${RESET}"
        echo -e "${CYAN}${BOLD}========================================${RESET}"
        echo ""
        echo -e "${WHITE}1. 查看下载历史${RESET}"
        echo -e "${WHITE}2. 清理临时文件${RESET}"
        echo -e "${WHITE}3. 查看日志${RESET}"
        echo -e "${WHITE}4. 重置配置${RESET}"
        echo -e "${WHITE}5. 系统信息${RESET}"
        echo -e "${WHITE}0. 返回${RESET}"
        echo ""
        
        local choice=$(get_user_choice 5)
        
        case $choice in
            0) break ;;
            1) show_download_history ;;
            2) cleanup_temp_files ;;
            3) show_logs ;;
            4) reset_config ;;
            5) show_system_info ;;
            *) echo -e "${RED}无效选择，请输入 0-5${RESET}" ;;
        esac
        
        if (( choice != 0 )); then
            echo ""
            read -p "按回车键继续..."
        fi
    done
}

# 查看下载历史
show_download_history() {
    show_title "下载历史"
    
    if [[ -d "$SaveDir" ]]; then
        echo -e "${BLUE}下载目录: $SaveDir${RESET}"
        echo ""
        ls -la "$SaveDir" 2>/dev/null || echo -e "${YELLOW}下载目录为空${RESET}"
    else
        echo -e "${YELLOW}下载目录不存在${RESET}"
    fi
}

# 清理临时文件
cleanup_temp_files() {
    show_title "清理临时文件"
    
    if [[ -d "$TempDir" ]]; then
        local size=$(du -sh "$TempDir" 2>/dev/null | cut -f1)
        echo -e "${BLUE}临时目录大小: $size${RESET}"
        
        if confirm_action "确认清理临时文件?"; then
            rm -rf "$TempDir"/*
            echo -e "${GREEN}临时文件已清理${RESET}"
            log "INFO" "临时文件已清理"
        fi
    else
        echo -e "${YELLOW}临时目录不存在${RESET}"
    fi
}

# 查看日志
show_logs() {
    show_title "查看日志"
    
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${BLUE}日志文件: $LOG_FILE${RESET}"
        echo ""
        tail -20 "$LOG_FILE" 2>/dev/null || echo -e "${YELLOW}日志文件为空${RESET}"
    else
        echo -e "${YELLOW}日志文件不存在${RESET}"
    fi
}

# 重置配置
reset_config() {
    show_title "重置配置"
    
    if confirm_action "确认重置所有配置为默认值?"; then
        rm -f "$CONFIG_FILE"
        load_config
        echo -e "${GREEN}配置已重置${RESET}"
        log "INFO" "配置已重置为默认值"
    fi
}

# 系统信息
show_system_info() {
    show_title "系统信息"
    
    echo -e "${BLUE}系统架构:${RESET} $(uname -m)"
    echo -e "${BLUE}操作系统:${RESET} $(uname -s)"
    echo -e "${BLUE}内核版本:${RESET} $(uname -r)"
    echo -e "${BLUE}脚本目录:${RESET} $SCRIPT_DIR"
    echo -e "${BLUE}下载目录:${RESET} $SaveDir"
    echo -e "${BLUE}临时目录:${RESET} $TempDir"
    echo ""
    
    if [[ -f "$REfile" ]]; then
        local version=$("$REfile" --version 2>/dev/null | head -1)
        echo -e "${BLUE}N_m3u8DL-RE版本:${RESET} $version"
    fi
    
    if [[ -f "$ffmpeg" ]]; then
        local version=$("$ffmpeg" -version 2>/dev/null | head -1)
        echo -e "${BLUE}ffmpeg版本:${RESET} $version"
    fi
}

# 设置
settings() {
    while true; do
        clear
        echo -e "${CYAN}${BOLD}========================================${RESET}"
        echo -e "${CYAN}${BOLD}  设置${RESET}"
        echo -e "${CYAN}${BOLD}========================================${RESET}"
        echo ""
        echo -e "${WHITE}1. 下载设置${RESET}"
        echo -e "${WHITE}2. 性能设置${RESET}"
        echo -e "${WHITE}3. 高级设置${RESET}"
        echo -e "${WHITE}4. 保存设置${RESET}"
        echo -e "${WHITE}0. 返回${RESET}"
        echo ""
        
        local choice=$(get_user_choice 4)
        
        case $choice in
            0) break ;;
            1) download_settings ;;
            2) performance_settings ;;
            3) advanced_settings ;;
            4) save_settings ;;
            *) echo -e "${RED}无效选择，请输入 0-4${RESET}" ;;
        esac
        
        if (( choice != 0 )); then
            echo ""
            read -p "按回车键继续..."
        fi
    done
}

# 下载设置
download_settings() {
    show_title "下载设置"
    
    echo -e "${BLUE}当前设置:${RESET}"
    echo -e "下载目录: $SaveDir"
    echo -e "重试次数: $RetryCount"
    echo -e "超时时间: $Timeout 秒"
    echo ""
    
    SaveDir=$(input_box "下载目录" "$SaveDir")
    RetryCount=$(input_box "重试次数" "$RetryCount")
    Timeout=$(input_box "超时时间(秒)" "$Timeout")
    
    echo -e "${GREEN}设置已更新${RESET}"
}

# 性能设置
performance_settings() {
    show_title "性能设置"
    
    echo -e "${BLUE}当前设置:${RESET}"
    echo -e "线程数: $ThreadCount"
    echo -e "并发下载: $ConcurrentDownload"
    echo -e "实时解密: $RealTimeDecryption"
    echo ""
    
    ThreadCount=$(input_box "线程数" "$ThreadCount")
    ConcurrentDownload=$(input_box "并发下载(true/false)" "$ConcurrentDownload")
    RealTimeDecryption=$(input_box "实时解密(true/false)" "$RealTimeDecryption")
    
    echo -e "${GREEN}设置已更新${RESET}"
}

# 高级设置
advanced_settings() {
    show_title "高级设置"
    
    echo -e "${BLUE}当前设置:${RESET}"
    echo -e "自动选择: $AutoSelect"
    echo -e "检查片段: $CheckSegments"
    echo -e "下载后删除: $DeleteAfterDone"
    echo -e "写入元数据: $WriteMetaJson"
    echo -e "附加URL参数: $AppendUrlParams"
    echo ""
    
    AutoSelect=$(input_box "自动选择(true/false)" "$AutoSelect")
    CheckSegments=$(input_box "检查片段(true/false)" "$CheckSegments")
    DeleteAfterDone=$(input_box "下载后删除(true/false)" "$DeleteAfterDone")
    WriteMetaJson=$(input_box "写入元数据(true/false)" "$WriteMetaJson")
    AppendUrlParams=$(input_box "附加URL参数(true/false)" "$AppendUrlParams")
    
    echo -e "${GREEN}设置已更新${RESET}"
}

# 保存设置
save_settings() {
    show_title "保存设置"
    
    if confirm_action "确认保存当前设置?"; then
        save_config
        echo -e "${GREEN}设置已保存${RESET}"
        log "INFO" "设置已保存"
    fi
}

# 自动更新
auto_update() {
    show_title "自动更新"
    
    if [[ -f "auto_update.sh" ]]; then
        chmod +x auto_update.sh
        ./auto_update.sh
    else
        echo -e "${RED}自动更新脚本不存在${RESET}"
    fi
}

# 主循环
main() {
    init
    
    while true; do
        show_main_menu
        local choice=$(get_user_choice 6)
        
        case $choice in
            0)
                echo -e "${GREEN}感谢使用!${RESET}"
                exit 0
                ;;
            1) single_download ;;
            2) batch_download ;;
            3) live_recording ;;
            4) advanced_features ;;
            5) settings ;;
            6) auto_update ;;
            *) echo -e "${RED}无效选择，请输入 0-6${RESET}" ;;
        esac
        
        if (( choice != 0 )); then
            echo ""
            read -p "按回车键返回主菜单..."
        fi
    done
}

# 运行主函数
main "$@" 
