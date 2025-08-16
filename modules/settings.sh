#!/bin/bash

# =============================================================================
# 设置模块
# =============================================================================

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
        echo -e "${WHITE}4. 字幕设置${RESET}"
        echo -e "${WHITE}5. 直播设置${RESET}"
        echo -e "${WHITE}6. 保存设置${RESET}"
        echo -e "${WHITE}0. 返回${RESET}"
        echo ""
        
        local choice=$(get_user_choice 6 "请选择 (0-6): ")
        
        case $choice in
            0) break ;;
            1) download_settings ;;
            2) performance_settings ;;
            3) advanced_settings ;;
            4) subtitle_settings ;;
            5) live_settings ;;
            6) save_settings ;;
            *) echo -e "${RED}无效选择，请输入 0-6${RESET}" ;;
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
    echo -e "限速设置: $MaxSpeed"
    echo -e "自定义范围: $CustomRange"
    echo ""
    
    set_config "SaveDir" "$(input_box "下载目录" "$SaveDir")"
    set_config "RetryCount" "$(input_box "重试次数" "$RetryCount")"
    set_config "Timeout" "$(input_box "超时时间(秒)" "$Timeout")"
    set_config "MaxSpeed" "$(input_box "限速设置(如15M, 100K，留空为不限制)" "$MaxSpeed")"
    set_config "CustomRange" "$(input_box "自定义范围(如1-100，留空为全部)" "$CustomRange")"
    
    echo -e "${GREEN}设置已更新，将在下次启动时生效${RESET}"
}

# 性能设置
performance_settings() {
    show_title "性能设置"
    
    echo -e "${BLUE}当前设置:${RESET}"
    echo -e "线程数: $ThreadCount"
    echo -e "并发下载: $ConcurrentDownload"
    echo -e "实时解密: $RealTimeDecryption"
    echo -e "检查片段: $CheckSegments"
    echo -e "二进制合并: $BinaryMerge"
    echo -e "使用FFmpeg连接分离器: $UseFFmpegConcatDemuxer"
    echo ""
    
    set_config "ThreadCount" "$(input_box "线程数" "$ThreadCount")"
    set_config "ConcurrentDownload" "$(get_boolean_choice "并发下载" "$ConcurrentDownload")"
    set_config "RealTimeDecryption" "$(get_boolean_choice "实时解密" "$RealTimeDecryption")"
    set_config "CheckSegments" "$(get_boolean_choice "检查片段" "$CheckSegments")"
    set_config "BinaryMerge" "$(get_boolean_choice "二进制合并" "$BinaryMerge")"
    set_config "UseFFmpegConcatDemuxer" "$(get_boolean_choice "使用FFmpeg连接分离器" "$UseFFmpegConcatDemuxer")"
    
    echo -e "${GREEN}设置已更新，将在下次启动时生效${RESET}"
}

# 高级设置
advanced_settings() {
    show_title "高级设置"
    
    echo -e "${BLUE}当前设置:${RESET}"
    echo -e "自动选择: $AutoSelect"
    echo -e "下载后删除: $DeleteAfterDone"
    echo -e "写入元数据: $WriteMetaJson"
    echo -e "附加URL参数: $AppendUrlParams"
    echo -e "无日期信息: $NoDateInfo"
    echo ""
    
    set_config "AutoSelect" "$(get_boolean_choice "自动选择" "$AutoSelect")"
    set_config "DeleteAfterDone" "$(get_boolean_choice "下载后删除" "$DeleteAfterDone")"
    set_config "WriteMetaJson" "$(get_boolean_choice "写入元数据" "$WriteMetaJson")"
    set_config "AppendUrlParams" "$(get_boolean_choice "附加URL参数" "$AppendUrlParams")"
    set_config "NoDateInfo" "$(get_boolean_choice "无日期信息" "$NoDateInfo")"
    
    echo -e "${GREEN}设置已更新，将在下次启动时生效${RESET}"
}

# 字幕设置
subtitle_settings() {
    show_title "字幕设置"
    
    echo -e "${BLUE}当前设置:${RESET}"
    echo -e "仅字幕: $SubOnly"
    echo -e "字幕格式: $SubFormat"
    echo -e "自动修正字幕: $AutoSubtitleFix"
    echo ""
    
    set_config "SubOnly" "$(get_boolean_choice "仅字幕" "$SubOnly")"
    set_config "SubFormat" "$(input_box "字幕格式(SRT/VTT)" "$SubFormat")"
    set_config "AutoSubtitleFix" "$(get_boolean_choice "自动修正字幕" "$AutoSubtitleFix")"
    
    echo -e "${GREEN}设置已更新，将在下次启动时生效${RESET}"
}

# 直播设置
live_settings() {
    show_title "直播设置"
    
    echo -e "${BLUE}当前设置:${RESET}"
    echo -e "以点播方式下载直播: $LivePerformAsVod"
    echo -e "实时合并: $LiveRealTimeMerge"
    echo -e "保留分片: $LiveKeepSegments"
    echo -e "管道混流: $LivePipeMux"
    echo ""
    
    set_config "LivePerformAsVod" "$(get_boolean_choice "以点播方式下载直播" "$LivePerformAsVod")"
    set_config "LiveRealTimeMerge" "$(get_boolean_choice "实时合并" "$LiveRealTimeMerge")"
    set_config "LiveKeepSegments" "$(get_boolean_choice "保留分片" "$LiveKeepSegments")"
    set_config "LivePipeMux" "$(get_boolean_choice "管道混流" "$LivePipeMux")"
    
    echo -e "${GREEN}设置已更新，将在下次启动时生效${RESET}"
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