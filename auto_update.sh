#!/bin/bash
#
# N_m3u8DL-RE 自动更新脚本
# 负责检查和更新核心组件
# 版本: 1.2.0
# 作者: lo3612
# 最后修改: $(date +%Y-%m-%d)

# 严格模式
set -euo pipefail
trap 'echo "[ERROR] 脚本异常退出，行号: $LINENO"; exit 1' ERR

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
    echo -e "${BLUE}检查N_m3u8DL-RE更新...${RESET}"
    
    local local_version=$(get_local_version)
    local remote_version=$(get_remote_version)
    
    if [[ -z "$remote_version" ]]; then
        echo -e "${RED}无法获取远程版本信息${RESET}"
        log "ERROR" "无法获取远程版本信息"
        return 1
    fi
    
    echo -e "本地版本: ${YELLOW}${local_version:-"未安装"}${RESET}"
    echo -e "远程版本: ${GREEN}$remote_version${RESET}"
    log "INFO" "本地版本: ${local_version:-"未安装"}, 远程版本: $remote_version"
    
    if [[ -z "$local_version" ]]; then
        echo -e "${YELLOW}本地未安装，将进行首次安装${RESET}"
        log "INFO" "本地未安装，将进行首次安装"
        return 0
    fi
    
    if version_gt "$remote_version" "$local_version"; then
        echo -e "${YELLOW}发现新版本，需要更新${RESET}"
        log "INFO" "发现新版本，需要更新"
        return 0
    else
        echo -e "${GREEN}已是最新版本${RESET}"
        log "INFO" "已是最新版本"
        return 2
    fi
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

# 检查磁盘空间
check_disk_space() {
    echo -e "${BLUE}检查磁盘空间...${RESET}"
    log "INFO" "检查磁盘空间"
    
    local required_space=200  # MB
    local available_space=$(df "$SCRIPT_DIR" | awk 'NR==2 {print int($4/1024)}')
    
    if [[ $available_space -lt $required_space ]]; then
        echo -e "${RED}磁盘空间不足，需要至少 ${required_space}MB 可用空间${RESET}"
        log "ERROR" "磁盘空间不足，需要至少 ${required_space}MB 可用空间，当前可用 ${available_space}MB"
        return 1
    else
        echo -e "${GREEN}磁盘空间充足 (${available_space}MB 可用)${RESET}"
        log "INFO" "磁盘空间充足 (${available_space}MB 可用)"
        return 0
    fi
}

# 主更新流程
main() {
    local update_n_m3u8dl=false
    local update_ffmpeg=false
    local force_update=false
    
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
            --force)
                force_update=true
                shift
                ;;
            --cleanup)
                cleanup_backups
                exit 0
                ;;
            *)
                echo -e "${RED}未知参数: $1${RESET}"
                echo -e "用法: $0 [--n-m3u8dl|--ffmpeg|--all|--force|--cleanup]"
                echo -e "  --n-m3u8dl  更新 N_m3u8DL-RE"
                echo -e "  --ffmpeg    更新 ffmpeg"
                echo -e "  --all       更新所有组件（默认）"
                echo -e "  --force     强制更新，即使已是最新版本"
                echo -e "  --cleanup   清理备份文件"
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定参数，检查所有组件
    if [[ "$update_n_m3u8dl" == "false" && "$update_ffmpeg" == "false" ]]; then
        update_n_m3u8dl=true
        update_ffmpeg=true
    fi
    
    # 检查磁盘空间
    if ! check_disk_space; then
        exit 1
    fi
    
    # 更新N_m3u8DL-RE
    if [[ "$update_n_m3u8dl" == "true" ]]; then
        echo ""
        echo -e "${CYAN}=== 更新N_m3u8DL-RE ===${RESET}"
        log "INFO" "开始更新N_m3u8DL-RE"
        
        local check_result=0
        if [[ "$force_update" == "false" ]]; then
            check_updates
            check_result=$?
        else
            echo -e "${YELLOW}强制更新模式${RESET}"
            log "INFO" "强制更新模式"
        fi
        
        if [[ $check_result -eq 0 ]] || [[ "$force_update" == "true" ]]; then
            if ! download_n_m3u8dl_re "update" "true" "$force_update"; then
                echo -e "${RED}N_m3u8DL-RE 更新失败，请检查日志${RESET}"
                log "ERROR" "N_m3u8DL-RE 更新失败"
                exit 1
            else
                echo -e "${GREEN}N_m3u8DL-RE 更新成功${RESET}"
                log "INFO" "N_m3u8DL-RE 更新成功"
            fi
        elif [[ $check_result -eq 1 ]]; then
            echo -e "${RED}N_m3u8DL-RE 更新检查失败，请检查网络连接或日志${RESET}"
            log "ERROR" "N_m3u8DL-RE 更新检查失败"
            exit 1
        elif [[ $check_result -eq 2 ]]; then
            echo -e "${GREEN}N_m3u8DL-RE 已是最新版本${RESET}"
            log "INFO" "N_m3u8DL-RE 已是最新版本"
        fi
    fi
    
    # 更新ffmpeg
    if [[ "$update_ffmpeg" == "true" ]]; then
        echo ""
        echo -e "${CYAN}=== 更新ffmpeg ===${RESET}"
        log "INFO" "开始更新ffmpeg"
        
        if [[ ! -f "ffmpeg" ]]; then
            echo -e "${YELLOW}ffmpeg未安装，将进行首次安装${RESET}"
            log "INFO" "ffmpeg未安装，将进行首次安装"
        fi
        
        # 如果是强制更新，备份现有版本
        local backup_ffmpeg="true"
        if [[ "$force_update" == "true" && -f "ffmpeg" ]]; then
            echo -e "${YELLOW}强制更新ffmpeg${RESET}"
            log "INFO" "强制更新ffmpeg"
        fi
        
        if ! download_ffmpeg "update" "$backup_ffmpeg" "$force_update"; then
            echo -e "${RED}ffmpeg 更新失败，请检查日志${RESET}"
            log "ERROR" "ffmpeg 更新失败"
            exit 1
        else
            echo -e "${GREEN}ffmpeg 更新成功${RESET}"
            log "INFO" "ffmpeg 更新成功"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}${BOLD}更新完成!${RESET}"
    log "INFO" "更新完成"
    echo -e "${CYAN}现在可以运行 ./start.sh 启动程序${RESET}"
}

# 运行主函数
main "$@"