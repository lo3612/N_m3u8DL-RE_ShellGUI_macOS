#!/bin/bash

# =============================================================================
# N_m3u8DL-RE 下载管理器
# 版本: 2.1.1
# 日期: 2025-8-8
# =============================================================================

# 引入公共函数库
source "$(dirname "${BASH_SOURCE}")/common.sh"

# 引入模块
source "$SCRIPT_DIR/modules/download.sh"
source "$SCRIPT_DIR/modules/settings.sh"
source "$SCRIPT_DIR/modules/advanced.sh"

# 程序路径
REfile="$SCRIPT_DIR/N_m3u8DL-RE"
ffmpeg="$SCRIPT_DIR/ffmpeg"

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"
LOG_FILE="$SCRIPT_DIR/m3u8dl.log"
LOCK_FILE="$SCRIPT_DIR/m3u8dl.lock"

# 默认配置 (已移至 common.sh 的 load_config 函数)

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
    echo -e "${WHITE}1. 下载管理${RESET}"
    echo -e "${WHITE}2. 高级功能${RESET}"
    echo -e "${WHITE}3. 设置${RESET}"
    echo -e "${WHITE}4. 自动更新${RESET}"
    echo -e "${WHITE}5. 清理备份${RESET}"
    echo -e "${WHITE}0. 退出程序${RESET}"
    echo ""
}



# 显示下载菜单
show_download_menu() {
    while true; do
        show_menu "下载管理" "单个视频下载" "批量下载" "直播录制"
        local choice=$(get_user_choice 3 "请选择 (0-3): ")
        
        case $choice in
            0) break ;;
            1) single_download ;;
            2) batch_download ;;
            3) live_recording ;;
            *) echo -e "${RED}无效选择，请输入 0-3${RESET}" ;;
        esac
        
        if (( choice != 0 )); then
            echo ""
            read -p "按回车键返回下载菜单..."
        fi
    done
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

# 清理备份 (菜单调用)
cleanup_backups_menu() {
    show_title "清理备份"
    if confirm_action "确认清理所有备份文件?"; then
        cleanup_backups
    fi
}

# 主循环
main() {
    init
    
    while true; do
        show_main_menu
        local choice=$(get_user_choice 5 "请选择 (0-5): ")
        
        case $choice in
            0)
                echo -e "${GREEN}感谢使用!${RESET}"
                exit 0
                ;;
            1) show_download_menu ;;
            2) advanced_features ;;
            3) settings ;;
            4) auto_update ;;
            5) cleanup_backups_menu ;;
            *) echo -e "${RED}无效选择，请输入 0-5${RESET}" ;;
        esac
        
        if (( choice != 0 )); then
            echo ""
            read -p "按回车键返回主菜单..."
        fi
    done
}

# 运行主函数
main "$@" 

# 清理备份 (菜单调用)
cleanup_backups_menu() {
    show_title "清理备份"
    if confirm_action "确认清理所有备份文件?"; then
        cleanup_backups
    fi
}
