# openEuler QEMU默认配置文件
# 用于单实例场景

# 实例配置
INSTANCE_NAME="default"
INSTANCE_ID="1"

# 资源路径
IMAGE_DIR="/home/volcano/myws/oee2403/build/qemu-aarch64/output/20260127163708"
KERNEL_PATH="$IMAGE_DIR/zImage"
ROOTFS_PATH="/home/volcano/myws/oee2403/build/qemu-aarch64/tmp/deploy/images/qemu-aarch64/openeuler-image-qemu-aarch64.cpio.gz"

# 持久化存储配置
# USE_PERSISTENT_STORAGE: 是否使用持久化存储 (true/false)
# DISK_IMG: 持久化磁盘镜像路径 (仅当 USE_PERSISTENT_STORAGE=true 时使用)
# 注意: DISK_IMG 会在启动脚本中被更新为相对于脚本所在目录的路径
USE_PERSISTENT_STORAGE="false"
DISK_IMG="${INSTANCE_NAME}_disk.img"

# QEMU配置
QEMU_BINARY=$(which qemu-system-aarch64 2>/dev/null || echo "/usr/bin/qemu-system-aarch64")

# 网络配置
SSH_PORT=2222
HTTP_PORT=8080
MONITOR_PORT=4444

# 硬件配置
CPU_CORES=2
MEMORY_SIZE=1024

# 密码配置
ROOT_PASSWORD="openEuler12#$"
