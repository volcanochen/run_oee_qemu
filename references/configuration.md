# 配置说明

本文档详细说明openEuler QEMU虚拟机的硬件、网络和存储配置。

## 硬件配置

### 机器类型

```bash
-machine virt,gic-version=3
```

- **virt**: ARM64通用虚拟机平台
- **gic-version=3**: 通用中断控制器版本3

### CPU配置

```bash
-cpu cortex-a53
-smp <CPU_CORES>
```

- **CPU类型**: cortex-a53 (ARMv8-A 64位处理器）
- **核心数**: 可配置（默认2核）
- **示例**:
  - 单核: `-smp 1`
  - 双核: `-smp 2` (默认）
  - 四核: `-smp 4`
  - 八核: `-smp 8`

### 内存配置

```bash
-m <MEMORY_SIZE>
```

- **单位**: MB
- **默认**: 1024MB (1GB)
- **示例**:
  - 512MB: `-m 512`
  - 1GB: `-m 1024` (默认）
  - 2GB: `-m 2048`
  - 4GB: `-m 4096`

## 网络配置

### 用户模式网络（User Mode）

```bash
-netdev user,id=net0,hostfwd=tcp::<SSH_PORT>-:22,hostfwd=tcp::<HTTP_PORT>-:80
-device virtio-net-device,netdev=net0
```

**特点**：
- 无需root权限
- 自动NAT转发
- Host端口映射到Guest端口
- Guest可以访问Host和外部网络
- 外部无法直接访问Guest（需要端口转发）

**端口映射**：
- Host `<SSH_PORT>` → Guest 22 (SSH)
- Host `<HTTP_PORT>` → Guest 80 (HTTP)

**适用场景**：
- 开发和测试
- 不需要外部访问Guest服务
- 快速启动和停止

**限制**：
- ICMP (ping) 不工作
- 某些网络协议可能受限
- 性能略低于TAP模式

### TAP接口网络（TAP Mode）

```bash
-netdev tap,id=net0,ifname=<TAP_IF>,script=qemu-ifup,downscript=no
-device virtio-net-device,netdev=net0
```

**特点**：
- 需要root权限
- 桥接到Host网络
- Guest和Host在同一网络段
- 完整的网络功能（包括ping）
- 更好的网络性能

**配置要求**：
1. 创建TAP接口脚本 `qemu-ifup`
2. 配置网桥（通常为br0）
3. 设置网络权限

**适用场景**：
- 需要完整网络功能
- 网络服务开发和调试
- 性能测试

### 端口配置

| 端口类型 | 默认端口 | 说明 |
|---------|---------|------|
| SSH | 2222 | SSH远程访问 |
| HTTP | 8080 | HTTP服务端口转发 |
| Monitor | 4444 | QEMU Monitor控制台 |

**多实例端口配置**：

为避免端口冲突，不同实例使用不同端口：

```bash
# 实例1 (default)
SSH_PORT=2222
HTTP_PORT=8080
MONITOR_PORT=4444

# 实例2 (scenario1)
SSH_PORT=2224
HTTP_PORT=8082
MONITOR_PORT=4446

# 实例3 (scenario2)
SSH_PORT=2226
HTTP_PORT=8084
MONITOR_PORT=4448
```

## 存储配置

### 根文件系统（Root Filesystem）

```bash
-kernel <KERNEL_PATH>
-initrd <ROOTFS_PATH>
-append "console=ttyAMA0,115200 earlycon=pl011,0x9000000 root=/dev/ram0 rw ip=dhcp modules-load=virtio_pci"
```

**特点**：
- 使用initramfs（内存文件系统）
- 只读文件系统
- 重启后数据不保留
- 快速启动

**文件格式**：
- 内核: `zImage` (压缩的Linux内核）
- 根文件系统: `*.cpio.gz` (压缩的CPIO归档）

**适用场景**：
- 快速启动和测试
- 不需要持久化存储
- 系统验证和调试

### 持久化存储（Persistent Storage）

```bash
-drive file=<DISK_IMG>,if=virtio,cache=none,aio=native,format=qcow2
```

**特点**：
- 使用qcow2格式（支持快照和压缩）
- 可读写文件系统
- 数据持久保存
- 支持在线扩容

**文件格式**：
- 格式: qcow2 (QEMU Copy-On-Write)
- 默认大小: 2GB
- 挂载点: `/mnt/persistent`

**创建磁盘镜像**：

```bash
# 创建2GB qcow2磁盘镜像
qemu-img create -f qcow2 default_disk.img 2G

# 扩容磁盘镜像
qemu-img resize default_disk.img +1G  # 增加1GB
```

**在Guest中使用持久化存储**：

```bash
# 格式化磁盘（首次使用）
mkfs.ext4 /dev/vda

# 创建挂载点
mkdir -p /mnt/persistent

# 挂载磁盘
mount /dev/vda /mnt/persistent

# 使用持久化存储
echo "Hello World" > /mnt/persistent/test.txt

# 卸载磁盘
umount /mnt/persistent
```

**启用持久化存储**：

```bash
./start_openeuler.sh user --persistent
```

**适用场景**：
- 需要保存数据
- 开发和测试需要持久化环境
- 应用程序数据存储

## 配置文件示例

### 默认配置（default_config.sh）

```bash
# 实例配置
INSTANCE_NAME="default"
INSTANCE_ID="1"

# 资源路径
IMAGE_DIR="/home/volcano/myws/oee2403/build/qemu-aarch64/output/20260127163708"
KERNEL_PATH="$IMAGE_DIR/zImage"
ROOTFS_PATH="/home/volcano/myws/oee2403/build/qemu-aarch64/tmp/deploy/images/qemu-aarch64/openeuler-image-qemu-aarch64.cpio.gz"
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
```

### 场景配置（scenario1_config.sh）

```bash
# 实例配置
INSTANCE_NAME="scenario1"
INSTANCE_ID="3"

# 资源路径
IMAGE_DIR="/home/volcano/myws/oee2403/build/qemu-aarch64/output/20260127163708"
KERNEL_PATH="$IMAGE_DIR/zImage"
ROOTFS_PATH="/home/volcano/myws/oee2403/build/qemu-aarch64/tmp/deploy/images/qemu-aarch64/openeuler-image-qemu-aarch64.cpio.gz"
DISK_IMG="${INSTANCE_NAME}_disk.img"

# QEMU配置
QEMU_BINARY=$(which qemu-system-aarch64 2>/dev/null || echo "/usr/bin/qemu-system-aarch64")

# 网络配置 (避免端口冲突)
SSH_PORT=2224
HTTP_PORT=8082
MONITOR_PORT=4446

# 硬件配置
CPU_CORES=4
MEMORY_SIZE=2048
```

## 配置最佳实践

### 资源分配

1. **CPU核心数**：
   - 开发测试: 2-4核
   - 性能测试: 4-8核
   - 多实例: 每实例1-2核

2. **内存大小**：
   - 基本使用: 512MB-1GB
   - 开发测试: 1-2GB
   - 性能测试: 2-4GB

3. **磁盘大小**：
   - 基本使用: 1-2GB
   - 开发测试: 2-4GB
   - 数据存储: 4GB+

### 端口管理

1. **端口规划**：
   - 为每个实例预留连续的端口范围
   - 记录端口分配情况
   - 避免端口冲突

2. **端口检查**：
   - 启动前检查端口占用
   - 使用 `netstat -tlnp | grep <PORT>` 检查
   - 冲突时调整端口配置

### 多实例隔离

1. **配置隔离**：
   - 每个实例独立配置文件
   - 独立的磁盘镜像
   - 独立的PID文件和日志

2. **资源隔离**：
   - 合理分配CPU和内存
   - 避免资源竞争
   - 监控资源使用情况

## 相关文档

- [SSH访问指南](ssh_access.md) - SSH连接和认证
- [故障排除文档](troubleshooting.md) - 常见问题和解决方案
