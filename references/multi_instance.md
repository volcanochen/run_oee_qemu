# 多实例配置指南

本文档详细说明如何配置和管理多个openEuler QEMU虚拟机实例。

## 概述

多实例配置允许同时运行多个QEMU虚拟机，每个实例拥有独立的配置、资源和网络端口，实现资源隔离和并行测试。

## 目录结构

```
run_oee_qemu/
└── scripts/
    ├── start_openeuler.sh         # 启动脚本（主入口）
    ├── stop_openeuler.sh          # 停止脚本
    ├── default_config.sh          # 默认配置（单实例）
    ├── scenario1_config.sh        # 场景1配置
    ├── scenario2_config.sh        # 场景2配置
    ├── <instance>_config.sh       # 自定义配置文件
    ├── default_disk.img          # 默认实例磁盘镜像
    ├── scenario1_disk.img        # 场景1磁盘镜像
    ├── scenario2_disk.img        # 场景2磁盘镜像
    ├── default_qemu.pid         # 默认实例PID文件
    ├── scenario1_qemu.pid       # 场景1PID文件
    ├── scenario2_qemu.pid       # 场景2PID文件
    ├── default_qemu.log         # 默认实例日志
    ├── scenario1_qemu.log       # 场景1日志
    └── scenario2_qemu.log       # 场景2日志
```

## 配置文件结构

每个实例使用独立的配置文件，配置文件命名规则：`<instance_name>_config.sh`

### 配置文件模板

```bash
# 实例配置
INSTANCE_NAME="<instance_name>"
INSTANCE_ID="<unique_id>"

# 资源路径
IMAGE_DIR="/path/to/oee2403/build/qemu-aarch64/output/<timestamp>"
KERNEL_PATH="$IMAGE_DIR/zImage"
ROOTFS_PATH="/path/to/openeuler-image-qemu-aarch64.cpio.gz"
DISK_IMG="${INSTANCE_NAME}_disk.img"

# QEMU配置
QEMU_BINARY=$(which qemu-system-aarch64 2>/dev/null || echo "/usr/bin/qemu-system-aarch64")

# 网络配置 (避免端口冲突)
SSH_PORT=<unique_port>
HTTP_PORT=<unique_port>
MONITOR_PORT=<unique_port>

# 硬件配置
CPU_CORES=<cores>
MEMORY_SIZE=<memory_mb>
```

## 端口规划

### 端口分配原则

1. **连续分配**：为每个实例预留连续的端口范围
2. **记录分配**：维护端口分配记录，避免冲突
3. **预留间隔**：实例间端口间隔至少2个端口

### 端口分配示例

| 实例 | SSH端口 | HTTP端口 | Monitor端口 | 说明 |
|------|---------|----------|-------------|------|
| default | 2222 | 8080 | 4444 | 默认实例 |
| scenario1 | 2224 | 8082 | 4446 | 场景1 |
| scenario2 | 2226 | 8084 | 4448 | 场景2 |
| scenario3 | 2228 | 8086 | 4450 | 场景3 |

### 端口检查

启动前检查端口是否被占用：

```bash
# 检查单个端口
netstat -tlnp | grep 2222

# 检查多个端口
for port in 2222 2224 2226; do
    netstat -tlnp | grep $port || echo "Port $port is free"
done
```

## 实例配置示例

### 实例1：默认配置（default_config.sh）

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

### 实例2：场景1配置（scenario1_config.sh）

```bash
# 实例配置
INSTANCE_NAME="scenario1"
INSTANCE_ID="2"

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

### 实例3：场景2配置（scenario2_config.sh）

```bash
# 实例配置
INSTANCE_NAME="scenario2"
INSTANCE_ID="3"

# 资源路径
IMAGE_DIR="/home/volcano/myws/oee2403/build/qemu-aarch64/output/20260127163708"
KERNEL_PATH="$IMAGE_DIR/zImage"
ROOTFS_PATH="/home/volcano/myws/oee2403/build/qemu-aarch64/tmp/deploy/images/qemu-aarch64/openeuler-image-qemu-aarch64.cpio.gz"
DISK_IMG="${INSTANCE_NAME}_disk.img"

# QEMU配置
QEMU_BINARY=$(which qemu-system-aarch64 2>/dev/null || echo "/usr/bin/qemu-system-aarch64")

# 网络配置 (避免端口冲突)
SSH_PORT=2226
HTTP_PORT=8084
MONITOR_PORT=4448

# 硬件配置
CPU_CORES=2
MEMORY_SIZE=1024
```

## 启动和管理实例

### 启动单个实例

```bash
# 启动默认实例
./start_openeuler.sh user

# 启动场景1实例
./start_openeuler.sh scenario1_config.sh

# 启动场景2实例
./start_openeuler.sh scenario2_config.sh
```

### 启动多个实例

```bash
# 在不同终端中启动多个实例
# 终端1
./start_openeuler.sh user

# 终端2
./start_openeuler.sh scenario1_config.sh

# 终端3
./start_openeuler.sh scenario2_config.sh
```

### 停止实例

```bash
# 按实例名称停止
./stop_openeuler.sh default
./stop_openeuler.sh scenario1
./stop_openeuler.sh scenario2

# 按PID停止
./stop_openeuler.sh 12345
```

### 查看运行中的实例

```bash
# 查看所有QEMU进程
ps aux | grep qemu-system-aarch64

# 查看特定实例的PID
cat default_qemu.pid
cat scenario1_qemu.pid
cat scenario2_qemu.pid

# 查看实例日志
tail -f default_qemu.log
tail -f scenario1_qemu.log
tail -f scenario2_qemu.log
```

## 访问多个实例

### SSH访问

```bash
# 访问默认实例
ssh -p 2222 root@localhost

# 访问场景1实例
ssh -p 2224 root@localhost

# 访问场景2实例
ssh -p 2226 root@localhost
```

### QEMU Monitor访问

```bash
# 访问默认实例Monitor
telnet localhost 4444

# 访问场景1实例Monitor
telnet localhost 4446

# 访问场景2实例Monitor
telnet localhost 4448
```

## 资源隔离

### 配置隔离

每个实例拥有独立的：
- 配置文件（`<instance>_config.sh`）
- 磁盘镜像（`<instance>_disk.img`）
- PID文件（`<instance>_qemu.pid`）
- 日志文件（`<instance>_qemu.log`）

### 资源隔离

每个实例使用独立的：
- 网络端口（SSH、HTTP、Monitor）
- CPU核心数（可配置）
- 内存大小（可配置）
- 磁盘空间（独立qcow2镜像）

### 网络隔离

每个实例拥有独立的：
- SSH端口
- HTTP端口转发
- Monitor端口
- 用户模式网络栈

## 资源分配建议

### CPU分配

| 场景 | 实例数 | 每实例CPU | 总CPU | 说明 |
|------|--------|-----------|--------|------|
| 轻量测试 | 2-3 | 1-2核 | 2-6核 | 基本功能测试 |
| 开发测试 | 2-3 | 2-4核 | 4-12核 | 应用开发 |
| 性能测试 | 1-2 | 4-8核 | 4-16核 | 性能基准测试 |

### 内存分配

| 场景 | 实例数 | 每实例内存 | 总内存 | 说明 |
|------|--------|------------|---------|------|
| 轻量测试 | 2-3 | 512MB-1GB | 1-3GB | 基本功能测试 |
| 开发测试 | 2-3 | 1-2GB | 2-6GB | 应用开发 |
| 性能测试 | 1-2 | 2-4GB | 2-8GB | 性能基准测试 |

### 磁盘分配

每个实例使用独立的qcow2磁盘镜像：
- 基本使用: 1-2GB
- 开发测试: 2-4GB
- 数据存储: 4GB+

## 使用场景

### 场景1：并行测试

同时运行多个实例，测试不同配置或版本：

```bash
# 终端1：测试版本A
./start_openeuler.sh versionA_config.sh

# 终端2：测试版本B
./start_openeuler.sh versionB_config.sh

# 终端3：测试版本C
./start_openeuler.sh versionC_config.sh
```

### 场景2：服务测试

每个实例运行不同的服务：

```bash
# 实例1：Web服务
./start_openeuler.sh web_config.sh

# 实例2：数据库服务
./start_openeuler.sh db_config.sh

# 实例3：应用服务
./start_openeuler.sh app_config.sh
```

### 场景3：网络测试

测试不同网络配置：

```bash
# 实例1：用户模式网络
./start_openeuler.sh user_config.sh

# 实例2：TAP网络
sudo ./start_openeuler.sh tap_config.sh
```

## 最佳实践

### 1. 配置管理

- 使用版本控制管理配置文件
- 为每个场景创建专用配置
- 记录配置变更历史
- 使用注释说明配置用途

### 2. 端口管理

- 维护端口分配文档
- 使用连续的端口范围
- 避免端口冲突
- 定期检查端口使用情况

### 3. 资源监控

- 监控CPU和内存使用
- 检查磁盘空间
- 查看实例日志
- 及时清理资源

### 4. 实例生命周期

- 及时停止不用的实例
- 定期清理临时文件
- 备份重要数据
- 维护实例文档

## 故障排除

### 端口冲突

**问题**：启动时提示端口被占用

**解决方案**：
1. 检查端口占用：`netstat -tlnp | grep <PORT>`
2. 停止占用进程：`kill <PID>`
3. 修改配置文件中的端口
4. 重新启动实例

### 资源不足

**问题**：系统资源不足，实例启动失败

**解决方案**：
1. 检查系统资源：`free -h`, `top`
2. 减少实例数量
3. 降低每个实例的CPU和内存配置
4. 停止其他占用资源的进程

### 实例无法访问

**问题**：无法SSH连接到实例

**解决方案**：
1. 检查实例是否运行：`ps aux | grep qemu`
2. 检查端口是否监听：`netstat -tlnp | grep <PORT>`
3. 检查防火墙设置
4. 查看实例日志：`tail -f <instance>_qemu.log`

## 相关文档

- [配置说明](configuration.md) - 硬件、网络和存储配置
- [SSH访问指南](ssh_access.md) - SSH连接和认证
- [故障排除文档](troubleshooting.md) - 常见问题和解决方案
