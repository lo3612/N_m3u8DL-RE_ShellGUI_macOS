#!/bin/bash

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# 开始
echo -e "${GREEN}N_m3u8DL-RE 下载调用 by RoadIsLong 2024.07.02${RESET}"

cd "$(dirname "$0")"

# 目录设置
REfile="./N_m3u8DL-RE"
TempDir="$HOME/Downloads/m3u8DL/temps"
SaveDir="$HOME/Downloads/m3u8DL/videos"
ffmpeg="/opt/homebrew/bin/ffmpeg"

# 增加最大打开文件数限制
ulimit -n 4096

# 菜单
menu() {
    clear
    echo ""
    echo -e "${CYAN}下载选项${RESET}"
    echo "**********************************************************"
    echo ""
    echo "1、单个 m3u8 视频下载"
    echo "2、批量 m3u8 视频下载"
    echo "3、直播录制"
    echo ""
    echo "**********************************************************"
    echo ""
    echo -e "* 当前设置主程序名: ${YELLOW}$REfile${RESET}"
    echo -e "* 当前设置输出目录: ${YELLOW}$SaveDir${RESET}"
    echo -e "* 当前设置临时目录: ${YELLOW}$TempDir${RESET}"
    echo -e "* 当前设置 FFMPEG 路径: ${YELLOW}$ffmpeg${RESET}"
    echo ""
    echo "**********************************************************"
    echo ""
    read -p "请输入操作序号并回车（1、2、3）：" a
    clear
    case "$a" in
        1) m3u8_download ;;
        2) m3u8_batch_download ;;
        3) live_record ;;
        *) echo -e "${RED}无效选项，请重新选择${RESET}" && menu ;;
    esac
}

setting_path() {
    input="input.txt"
    output="output.sh"
}

setting_m3u8_params() {
    m3u8_params="--thread-count 16 --download-retry-count 9 --auto-select --check-segments-count --no-log --append-url-params -mt --mp4-real-time-decryption --ui-language zh-CN"
}

setting_live_record_params() {
    live_record_params="--no-log -mt --mp4-real-time-decryption --ui-language zh-CN -sv best -sa best --live-pipe-mux --live-keep-segments --live-fix-vtt-by-audio $live_record_limit -M format=mp4:bin_path=\"$ffmpeg\""
}

m3u8_download() {
    common_input
    setting_path
    setting_m3u8_params
    m3u8_download_print
    m3u8_downloading
    when_done
}

m3u8_batch_download() {
    setting_path
    batch_input
    setting_m3u8_params
    batch_execute
    when_done
}

live_record() {
    common_input
    live_record_input
    setting_path
    setting_live_record_params
    live_record_print
    live_recording
    when_done
}

common_input() {
    read -p "请输入链接: " link
    if [ -z "$link" ]; then
        echo -e "${RED}错误：输入不能为空！${RESET}"
        common_input
    fi
    read -p "请输入保存文件名: " filename
    if [ -z "$filename" ]; then
        echo -e "${RED}错误：输入不能为空！${RESET}"
        common_input
    fi
}

batch_input() {
    read -p "请输入包含批量下载链接的文件名或完整路径（**.txt，留空则默认设置当前文件夹的 input.txt）: " batchfile_input
    [ -n "$batchfile_input" ] && input="$batchfile_input"
    read -p "请输入输出批量下载 sh 文件名（不带后缀名 .sh，留空则默认设置当前文件夹的 output.sh）: " batchfile_output
    [ -n "$batchfile_output" ] && output="$batchfile_output.sh"
}

batch_execute() {
    params="--tmp-dir \"$TempDir\" --save-dir \"$SaveDir\" --ffmpeg-binary-path \"$ffmpeg\" $m3u8_params"
    count=$(wc -l < "$input")
    cur_line=0
    > "$output"
    while IFS="$" read -r filename link; do
        ((cur_line++))
        outstring="$REfile \"$link\" --save-name \"$filename\" $params"
        echo "$outstring" >> "$output"
    done < "$input"
    clear
    chmod +x "$output"
    ./"$output"
}

live_record_input() {
    read -p "请输入录制时长限制（格式：HH:mm:ss，可为空）: " record_limit
    [ -z "$record_limit" ] && live_record_limit="" || live_record_limit="--live-record-limit $record_limit"
}

m3u8_download_print() {
    echo -e "${PURPLE}下载命令:${RESET} $REfile \"$link\" --save-name \"$filename\" $m3u8_params --ffmpeg-binary-path $ffmpeg --tmp-dir $TempDir --save-dir $SaveDir"
}

live_record_print() {
    echo -e "${PURPLE}录制命令:${RESET} $REfile \"$link\" --save-name \"$filename\" $live_record_params --ffmpeg-binary-path $ffmpeg --tmp-dir $TempDir --save-dir $SaveDir"
}

m3u8_downloading() {
    $REfile "$link" --save-name "$filename" $m3u8_params --ffmpeg-binary-path $ffmpeg --tmp-dir $TempDir --save-dir $SaveDir
}

live_recording() {
    $REfile "$link" --save-name "$filename" $live_record_params --ffmpeg-binary-path $ffmpeg --tmp-dir $TempDir --save-dir $SaveDir
}

when_done() {
    echo ""
    echo ""
    echo ""
    echo "**********************************************************"
    echo ""
    echo "  程序结束. 5 秒后自动关闭"
    echo ""
    echo "**********************************************************"
    echo ""
    echo ""
    echo ""
    sleep 5
    exit
}

menu
