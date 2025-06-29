#!/bin/bash

# 自动更新脚本

# 引入公共函数库
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo -e "${CYAN}${BOLD}========================================${RESET}"
echo -e "${CYAN}${BOLD}    N_m3u8DL-RE 自动更新${RESET}"
echo -e "${CYAN}${BOLD}========================================${RESET}"
echo ""

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 检查更新
check_updates() {
    echo -e "${BLUE}检查更新...${RESET}"
    
    local local_version=$(get_local_version)
    local remote_version=$(get_remote_version)
    
    if [[ -z "$remote_version" ]]; then
        echo -e "${RED}无法获取远程版本信息${RESET}"
        return 1
    fi
    
    echo -e "本地版本: ${YELLOW}${local_version:-"未安装"}${RESET}"
    echo -e "远程版本: ${GREEN}$remote_version${RESET}"
    
    if [[ -z "$local_version" ]]; then
        echo -e "${YELLOW}本地未安装，将进行首次安装${RESET}"
        return 0
    fi
    
    # 只提取主版本号数字部分进行比较，忽略beta等后缀
    local local_major=$(echo "$local_version" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    local remote_major=$(echo "$remote_version" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    
    if [[ "$local_major" == "$remote_major" ]]; then
        echo -e "${GREEN}已是最新版本${RESET}"
        return 2
    else
        echo -e "${YELLOW}发现新版本，需要更新${RESET}"
        return 0
    fi
}

# 清理备份
cleanup_backups() {
    echo -e "${BLUE}清理备份文件...${RESET}"
    
    if [[ -f "N_m3u8DL-RE.backup" ]]; then
        rm -f "N_m3u8DL-RE.backup"
        echo -e "${GREEN}已清理N_m3u8DL-RE备份${RESET}"
    fi
    
    if [[ -f "ffmpeg.backup" ]]; then
        rm -f "ffmpeg.backup"
        echo -e "${GREEN}已清理ffmpeg备份${RESET}"
    fi
}

# 主更新流程
main() {
    local update_n_m3u8dl=false
    local update_ffmpeg=false
    
    # 检查参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --n-m3u8dl)
                update_n_m3u8dl=true
                shift
                ;;
            --ffmpeg)
                update_ffmpeg=true
                shift
                ;;
            --all)
                update_n_m3u8dl=true
                update_ffmpeg=true
                shift
                ;;
            --cleanup)
                cleanup_backups
                exit 0
                ;;
            *)
                echo -e "${RED}未知参数: $1${RESET}"
                echo -e "用法: $0 [--n-m3u8dl|--ffmpeg|--all|--cleanup]"
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定参数，检查所有组件
    if [[ "$update_n_m3u8dl" == "false" && "$update_ffmpeg" == "false" ]]; then
        update_n_m3u8dl=true
        update_ffmpeg=true
    fi
    
    # 更新N_m3u8DL-RE
    if [[ "$update_n_m3u8dl" == "true" ]]; then
        echo ""
        echo -e "${CYAN}=== 更新N_m3u8DL-RE ===${RESET}"
        
        local check_result
        check_updates
        check_result=$?
        
        if [[ $check_result -eq 0 ]]; then
            if ! download_n_m3u8dl_re "update" "true"; then
                echo -e "${RED}N_m3u8DL-RE 更新失败${RESET}"
                exit 1
            fi
        elif [[ $check_result -eq 2 ]]; then
            echo -e "${GREEN}N_m3u8DL-RE 已是最新版本${RESET}"
        fi
    fi
    
    # 更新ffmpeg
    if [[ "$update_ffmpeg" == "true" ]]; then
        echo ""
        echo -e "${CYAN}=== 更新ffmpeg ===${RESET}"
        
        if [[ ! -f "ffmpeg" ]]; then
            echo -e "${YELLOW}ffmpeg未安装，将进行首次安装${RESET}"
        fi
        
        if ! download_ffmpeg "update" "true"; then
            echo -e "${RED}ffmpeg 更新失败${RESET}"
            exit 1
        fi
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}更新完成!${RESET}"
    echo -e "${CYAN}现在可以运行 ./start.sh 启动程序${RESET}"
}

# 运行主函数
main "$@" 
