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
    echo "警告: N_m3u8DL-RE 程序不存在"
    echo "将尝试自动下载..."
    
    if [[ -f "auto_update.sh" ]]; then
        chmod +x auto_update.sh
        ./auto_update.sh
    else
        echo "错误: 自动更新脚本不存在，请手动下载N_m3u8DL-RE"
        exit 1
    fi
else
    echo "✓ N_m3u8DL-RE 存在"
fi

# 检查ffmpeg
if [[ ! -f "ffmpeg" ]]; then
    echo "警告: ffmpeg 程序不存在"
    echo "将尝试自动下载..."
    
    if [[ -f "auto_update.sh" ]]; then
        chmod +x auto_update.sh
        ./auto_update.sh
    else
        echo "错误: 自动更新脚本不存在，请手动下载ffmpeg"
        exit 1
    fi
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
chmod +x auto_update.sh 2>/dev/null
echo "✓ 权限设置完成"
echo ""

# 启动程序
echo "启动 N_m3u8DL-RE..."
echo ""
./m3u8DL_enhanced.sh 