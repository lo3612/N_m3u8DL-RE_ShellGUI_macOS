#!/bin/bash

# =============================================================================
# 高级功能模块
# =============================================================================

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
        
        local choice=$(get_user_choice 5 "请选择 (0-5): ")
        
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