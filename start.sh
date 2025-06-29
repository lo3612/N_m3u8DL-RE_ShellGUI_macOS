#!/bin/bash

# 快速启动脚本

echo "=========================================="
echo "  N_m3u8DL-RE 下载管理器"
echo "=========================================="
echo ""

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 检查必要文件
echo "检查必要文件..."

# 检查N_m3u8DL-RE
if [[ ! -f "N_m3u8DL-RE" ]]; then
    echo "错误: N_m3u8DL-RE 程序不存在"
    echo "请先运行 ./install.sh 进行安装"
    exit 1
else
    echo "✓ N_m3u8DL-RE 存在"
fi

# 检查ffmpeg
if [[ ! -f "ffmpeg" ]]; then
    echo "错误: ffmpeg 程序不存在"
    echo "请先运行 ./install.sh 进行安装"
    exit 1
else
    echo "✓ ffmpeg 存在"
fi

# 检查主程序脚本
if [[ ! -f "m3u8DL_enhanced.sh" ]]; then
    echo "错误: m3u8DL_enhanced.sh 脚本不存在"
    exit 1
fi

echo "✓ 所有必要文件存在"
echo ""

# 设置执行权限
echo "设置执行权限..."
chmod +x N_m3u8DL-RE 2>/dev/null
chmod +x ffmpeg 2>/dev/null
chmod +x m3u8DL_enhanced.sh
echo "✓ 权限设置完成"
echo ""

# 启动程序
echo "启动 N_m3u8DL-RE..."
echo ""
./m3u8DL_enhanced.sh 
