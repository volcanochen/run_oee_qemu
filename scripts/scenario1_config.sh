# openEuler QEMU多实例配置文件
# 用于多实例场景

# 实例配置
INSTANCE_NAME="scenario1"
INSTANCE_ID="3"

# 资源路径
IMAGE_DIR="/home/volcano/myws/oee2403/build/qemu-aarch64/output/20260127163708"
KERNEL_PATH="$IMAGE_DIR/zImage"
ROOTFS_PATH="/home/volcano/myws/oee2403/build/qemu-aarch64/tmp/deploy/images/qemu-aarch64/openeuler-image-qemu-aarch64.cpio.gz"

# 持久化存储配置
USE_PERSISTENT_STORAGE="true"
DISK_IMG="/home/volcano/myws/oee2403/qemu_oee/scenario1_disk.img"

# QEMU配置
QEMU_BINARY=$(which qemu-system-aarch64 2>/dev/null || echo "/usr/bin/qemu-system-aarch64")

# 网络配置 (需要与默认实例不同以避免端口冲突)
SSH_PORT=2224
HTTP_PORT=8082
MONITOR_PORT=4446

# 硬件配置
CPU_CORES=4
MEMORY_SIZE=2048

# 密码配置
ROOT_PASSWORD="openEuler12#$"
