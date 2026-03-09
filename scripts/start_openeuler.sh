#!/bin/bash

# openEuler QEMU启动脚本
# 支持持久存储、网络连接及Host-Guest互访
# 支持多实例隔离和配置文件

set -e  # 遇到错误时立即退出脚本

# 检查参数
NETWORK_MODE="user"  # 默认使用用户模式网络
CONFIG_FILE=""
USE_PERSISTENT_STORAGE="false"  # 默认不持久化
PERSISTENT_SET_FROM_CMDLINE="false"  # 标记是否从命令行设置了持久化
VERBOSE="false"  # 默认不打印详细调试信息
SHOW_GUEST_OS_INFO="false"  # 默认不打印系统版本信息
CHECK_NETWORK="false"  # 默认不检查网络配置

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --persistent)
            USE_PERSISTENT_STORAGE="true"
            PERSISTENT_SET_FROM_CMDLINE="true"
            shift
            ;;
        --verbose|-v)
            VERBOSE="true"
            shift
            ;;
        --guest-os-info|-g)
            SHOW_GUEST_OS_INFO="true"
            shift
            ;;
        --check-network|-n)
            CHECK_NETWORK="true"
            shift
            ;;
        user)
            NETWORK_MODE="user"
            shift
            ;;
        tap)
            NETWORK_MODE="tap"
            shift
            ;;
        *)
            if [ -f "$1" ]; then
                CONFIG_FILE="$1"
            else
                # 输出使用帮助信息
                echo "用法: $0 [user|tap|config_file] [--persistent] [--verbose] [--guest-os-info] [--check-network]"
                echo "  user: 使用用户模式网络 (默认)"
                echo "  tap:  使用TAP接口网络"
                echo "  config_file: 使用配置文件"
                echo "  --persistent: 启用持久化存储 (默认不启用)"
                echo "  --verbose, -v: 显示详细调试信息"
                echo "  --guest-os-info, -g: 启动后显示Guest OS版本信息"
                echo "  --check-network, -n: 启动后检查网络配置"
                exit 1  # 参数错误则退出
            fi
            shift
            ;;
    esac
done

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 调试输出函数
verbose() {
    if [ "$VERBOSE" = "true" ]; then
        echo "$@"
    fi
}

# 检查端口占用函数
# 参数: $1 = "before" 或 "after" (启动前或启动后检查)
check_ports() {
    local CHECK_TYPE="$1"
    local PORT_CONFLICT=0
    
    echo ""
    if [ "$CHECK_TYPE" = "before" ]; then
        echo "=== 启动前端口检查 ==="
    else
        echo "=== 启动后端口检查 ==="
    fi
    
    for PORT in $SSH_PORT $MONITOR_PORT $HTTP_PORT; do
        if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
            USAGE=$(ss -tlnp 2>/dev/null | grep ":${PORT} " | head -1)
            PID=$(echo "$USAGE" | grep -oP 'pid=\K[0-9]+' || echo "未知")
            if [ "$CHECK_TYPE" = "before" ]; then
                echo "[错误] 端口 $PORT 被占用 (PID: $PID)"
                PORT_CONFLICT=1
            else
                echo "[OK] 端口 $PORT 已监听 (PID: $PID)"
            fi
        else
            if [ "$CHECK_TYPE" = "before" ]; then
                echo "[OK] 端口 $PORT 可用"
            else
                echo "[错误] 端口 $PORT 未监听"
                PORT_CONFLICT=1
            fi
        fi
    done
    
    if [ "$CHECK_TYPE" = "before" ] && [ "$PORT_CONFLICT" = "1" ]; then
        echo ""
        echo "请先停止占用端口的进程，或使用不同的端口配置"
        return 1
    fi
    
    if [ "$CHECK_TYPE" = "after" ] && [ "$PORT_CONFLICT" = "1" ]; then
        echo ""
        echo "警告: 部分端口未正常监听"
        return 1
    fi
    
    return 0
}

# 如果没有指定配置文件，使用默认配置
if [ -z "$CONFIG_FILE" ]; then
    CONFIG_FILE="$SCRIPT_DIR/default_config.sh"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "错误: 找不到配置文件: $CONFIG_FILE"
        echo "请创建配置文件或指定配置文件路径"
        exit 1
    fi
fi

# 加载配置文件
source "$CONFIG_FILE"

# 如果从命令行设置了持久化，覆盖配置文件中的值
if [ "$PERSISTENT_SET_FROM_CMDLINE" == "true" ]; then
    USE_PERSISTENT_STORAGE="true"
fi

# 将DISK_IMG更新为相对于脚本所在目录的路径
DISK_IMG="$SCRIPT_DIR/$DISK_IMG"

# 检查必要文件是否存在
if [ ! -f "$KERNEL_PATH" ]; then
    echo "错误: 找不到内核文件: $KERNEL_PATH"
    exit 1
fi

if [ ! -f "$ROOTFS_PATH" ]; then
    echo "错误: 找不到根文件系统: $ROOTFS_PATH"
    exit 1
fi

if [ ! -x "$QEMU_BINARY" ]; then
    echo "错误: 找不到QEMU二进制文件: $QEMU_BINARY"
    exit 1
fi

# 检查持久存储磁盘镜像（仅当启用持久化存储时）
if [ "$USE_PERSISTENT_STORAGE" == "true" ]; then
    if [ ! -f "$DISK_IMG" ]; then
        echo "错误: 找不到持久存储磁盘镜像: $DISK_IMG"
        echo "请按以下步骤创建磁盘镜像："
        echo "  1. 运行以下命令创建qcow2格式的磁盘镜像："
        echo "     qemu-img create -f qcow2 '$DISK_IMG' 2G"
        echo "  2. 然后重新运行此脚本"
        exit 1
    fi
fi

# 网络配置脚本 (仅在TAP模式下需要)
if [ "$NETWORK_MODE" == "tap" ]; then
    NET_SCRIPT="$SCRIPT_DIR/qemu-ifup"  # TAP网络配置脚本路径（基于脚本位置）
    if [ ! -f "$NET_SCRIPT" ]; then
        echo "错误: 网络配置脚本不存在: $NET_SCRIPT"
        echo "请先运行: ./qemu-ifup <interface_name>"
        exit 1
    fi
    chmod +x "$NET_SCRIPT"
fi

echo "启动openEuler QEMU虚拟机..."
echo "  实例: $INSTANCE_NAME"
if [ "$USE_PERSISTENT_STORAGE" == "true" ]; then
    # 显示配置文件信息
    if [ -f "$CONFIG_FILE" ]; then
        CONFIG_TIME=$(stat -c %y "$CONFIG_FILE" | cut -d'.' -f1)
        CONFIG_HASH=$(md5sum "$CONFIG_FILE" | awk '{print $1}')
        echo "  配置: $CONFIG_FILE  $CONFIG_TIME  $CONFIG_HASH"
    else
        echo "  配置: $CONFIG_FILE  ERROR: 文件不存在"
    fi
    
    # 显示磁盘镜像信息
    if [ -f "$DISK_IMG" ]; then
        DISK_TIME=$(stat -c %y "$DISK_IMG" | cut -d'.' -f1)
        DISK_HASH=$(md5sum "$DISK_IMG" | awk '{print $1}')
        echo "  持久化存储: 已启用 ($DISK_IMG)  $DISK_TIME  $DISK_HASH"
    else
        echo "  持久化存储: 已启用 ($DISK_IMG)  ERROR: 文件不存在"
    fi
else
    echo "  配置: $CONFIG_FILE"
    echo "  持久化存储: 未启用"
fi

# 日志文件路径
LOG_FILE="$SCRIPT_DIR/${INSTANCE_NAME}_qemu.log"

# 启动前检查端口
check_ports "before" || exit 1

# 构建QEMU启动参数
QEMU_ARGS=(
    -machine virt,gic-version=3
    -cpu cortex-a53
    -smp $CPU_CORES
    -m $MEMORY_SIZE
    -kernel "$KERNEL_PATH"
    -initrd "$ROOTFS_PATH"
    -append "console=ttyAMA0,115200 earlycon=pl011,0x9000000 root=/dev/ram0 rw ip=dhcp modules-load=virtio_pci"
    -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22,hostfwd=tcp::${HTTP_PORT}-:80
    -device virtio-net-device,netdev=net0
    -nographic
    -monitor telnet:127.0.0.1:${MONITOR_PORT},server,nowait
)

# 如果启用持久化存储，添加磁盘镜像
if [ "$USE_PERSISTENT_STORAGE" == "true" ]; then
    QEMU_ARGS+=(
        -drive file="$DISK_IMG",if=virtio,cache=none,aio=native,format=qcow2
    )
fi

# 根据网络模式启动QEMU
if [ "$NETWORK_MODE" == "user" ]; then
    "$QEMU_BINARY" "${QEMU_ARGS[@]}" > "$LOG_FILE" 2>&1 &
elif [ "$NETWORK_MODE" == "tap" ]; then
    sudo "$QEMU_BINARY" \
        -machine virt,gic-version=3 \
        -cpu cortex-a53 \
        -smp $CPU_CORES \
        -m $MEMORY_SIZE \
        -kernel "$KERNEL_PATH" \
        -initrd "$ROOTFS_PATH" \
        -append "console=ttyAMA0,115200 earlycon=pl011,0x9000000 root=/dev/ram0 rw ip=dhcp modules-load=virtio_pci" \
        -netdev tap,id=net0,ifname=tap0,script="$SCRIPT_DIR/qemu-ifup",downscript=no \
        -device virtio-net-device,netdev=net0 \
        -nographic \
        -monitor telnet:127.0.0.1:${MONITOR_PORT},server,nowait \
        > "$LOG_FILE" 2>&1 &
fi

# 等待QEMU启动
sleep 2

# 启动后检查端口
check_ports "after"

# 查找QEMU进程
verbose "正在查找QEMU进程..."
QEMU_PID=$(pgrep -f "qemu-system-aarch64" | head -1)
verbose "找到QEMU进程: $QEMU_PID"

if [ -z "$QEMU_PID" ]; then
    echo ""
    echo "错误: QEMU未能启动"
    echo ""
    echo "=== 诊断信息 ==="
    
    # 检查端口是否被占用
    for PORT in $SSH_PORT $MONITOR_PORT $HTTP_PORT; do
        if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
            USAGE=$(ss -tlnp 2>/dev/null | grep ":${PORT} " | head -1)
            PID=$(echo "$USAGE" | grep -oP 'pid=\K[0-9]+' || echo "未知")
            echo "[错误] 端口 $PORT 被占用 (PID: $PID)"
        fi
    done
    
    # 检查是否有残留进程
    RESIDUAL=$(pgrep -af qemu)
    if [ -n "$RESIDUAL" ]; then
        echo ""
        echo "残留QEMU进程:"
        echo "$RESIDUAL" | while read line; do echo "  $line"; done
    fi
    
    # 打印日志
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "=== QEMU日志 (最后10行) ==="
        tail -10 "$LOG_FILE"
        echo ""
        echo "=== 日志文件路径 ==="
        echo "$LOG_FILE"
    else
        echo "日志文件不存在: $LOG_FILE"
    fi
    
    # 检查日志中是否有错误信息
    if [ -f "$LOG_FILE" ]; then
        ERROR_COUNT=$(grep -ci "error\|fail\|killed\|signal\|terminat" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo ""
            echo "=== 日志中的错误关键词 ==="
            grep -i "error\|fail\|killed\|signal\|terminat" "$LOG_FILE" | tail -5
        fi
    fi
    
    exit 1
fi

# 保存PID到文件
echo $QEMU_PID > "$SCRIPT_DIR/${INSTANCE_NAME}_qemu.pid"

echo "QEMU运行中，PID: $QEMU_PID"
echo "停止命令: $SCRIPT_DIR/stop_openeuler.sh $INSTANCE_NAME"
echo "停止命令: $SCRIPT_DIR/stop_openeuler.sh $QEMU_PID"

# 打印进程详细信息
verbose ""
verbose "=== 进程信息 ==="
verbose "$(ps -p $QEMU_PID -o pid,ppid,cmd,etime,stat 2>/dev/null || echo '无法获取进程信息')"

# 获取Guest OS版本信息的函数
get_guest_os_version() {
    local GUEST_OS_VERSION
    
    # 使用expect获取版本信息
    GUEST_OS_VERSION=$(expect -c '
        set timeout 30
        spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost
        expect {
            "New password:" {
                send "openEuler12#$\r"
                expect "Retype new password:"
                send "openEuler12#$\r"
                expect "#"
            }
            "password:" {
                send "openEuler12#$\r"
                expect "#"
            }
            "#" {}
            timeout {
                puts "ERROR: SSH connection timeout"
                exit 1
            }
        }
        send "uname -a\r"
        expect "#"
        send "cat /etc/os-release\r"
        expect "#"
        send "exit\r"
        expect eof
    ' 2>/dev/null)
    
    echo "$GUEST_OS_VERSION"
}

# 如果需要显示版本信息
if [ "$SHOW_GUEST_OS_INFO" = "true" ]; then
    echo ""
    echo "=== Guest OS 已启动 ==="
    
    # 等待SSH服务就绪
    echo "等待SSH服务就绪..."
    sleep 5
    
    # 获取版本信息
    echo "获取系统版本信息..."
    GUEST_OS_VERSION=$(get_guest_os_version)
    
    echo ""
    echo "=== 系统版本信息 ==="
    if [ "$VERBOSE" = "true" ]; then
        echo "$GUEST_OS_VERSION"
    else
        echo "$GUEST_OS_VERSION" | grep -E "^(Linux|ID=|NAME=|VERSION=|PRETTY_NAME=)" | head -10
    fi
    echo ""
fi

# 如果需要检查网络配置
if [ "$CHECK_NETWORK" = "true" ] && [ -f "$SCRIPT_DIR/check_network.sh" ]; then
    echo ""
    echo "=== 网络配置检查 ==="
    bash "$SCRIPT_DIR/check_network.sh" "$SSH_PORT" 30 5 3
    echo ""
fi
