#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PARAM="${1:-default}"

# 检查参数是PID还是实例名称
if [[ "$PARAM" =~ ^[0-9]+$ ]]; then
    # 按PID停止
    QEMU_PID="$PARAM"
    INSTANCE_NAME="PID:$QEMU_PID"
    
    # 检查进程是否存在
    if ! ps -p "$QEMU_PID" > /dev/null 2>&1; then
        echo "错误: 进程 $QEMU_PID 不存在"
        exit 1
    fi
    
    # 尝试正常终止
    kill "$QEMU_PID" 2>/dev/null
    
    # 等待进程退出（最多等5秒）
    for i in {1..5}; do
        if ! ps -p "$QEMU_PID" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # 如果进程还在，强制终止
    if ps -p "$QEMU_PID" > /dev/null 2>&1; then
        kill -9 "$QEMU_PID" 2>/dev/null
        sleep 1
    fi
    
    # 再次检查是否还有进程
    if ! ps -p "$QEMU_PID" > /dev/null 2>&1; then
        echo "QEMU已停止 (PID: $QEMU_PID)"
        exit 0
    else
        echo "警告: 进程 $QEMU_PID 仍在运行"
        exit 1
    fi
else
    # 按实例名称停止
    INSTANCE_NAME="$PARAM"
    PID_FILE="$SCRIPT_DIR/${INSTANCE_NAME}_qemu.pid"
    
    # 检查PID文件是否存在
    if [ -f "$PID_FILE" ]; then
        QEMU_PID=$(cat "$PID_FILE")
        
        # 检查进程是否存在
        if ps -p "$QEMU_PID" > /dev/null 2>&1; then
            # 尝试正常终止
            kill "$QEMU_PID" 2>/dev/null
            
            # 等待进程退出（最多等5秒）
            for i in {1..5}; do
                if ! ps -p "$QEMU_PID" > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done
            
            # 如果进程还在，强制终止
            if ps -p "$QEMU_PID" > /dev/null 2>&1; then
                kill -9 "$QEMU_PID" 2>/dev/null
                sleep 1
            fi
        fi
        
        # 删除PID文件
        rm -f "$PID_FILE"
    fi
    
    # 清理残留的QEMU进程（防止PID文件丢失的情况）
    QEMU_PIDS=$(pgrep -f qemu-system-aarch64)
    if [ -n "$QEMU_PIDS" ]; then
        for pid in $QEMU_PIDS; do
            kill "$pid" 2>/dev/null
        done
        
        # 等待进程退出
        sleep 1
        
        # 强制终止可能残留的进程
        for pid in $QEMU_PIDS; do
            if ps -p "$pid" > /dev/null 2>&1; then
                kill -9 "$pid" 2>/dev/null
            fi
        done
    fi
    
    # 再次检查是否还有QEMU进程
    REMAINING=$(pgrep -f qemu-system-aarch64)
    if [ -z "$REMAINING" ]; then
        echo "QEMU已停止"
        exit 0
    else
        echo "警告: 仍有QEMU进程运行: $REMAINING"
        exit 1
    fi
fi
