# openEuler QEMU虚拟机启动

启动openEuler嵌入式系统QEMU虚拟机，支持用户模式网络和TAP接口网络，包含持久存储、端口转发、QEMU Monitor访问等功能。

## 使用场景

- 开发和测试openEuler嵌入式系统
- 验证内核修改和驱动程序
- 网络服务开发和调试
- 系统性能测试
- 多实例隔离测试
- 验证OpenEuler系统功能：快速验证OpenEuler系统的基本功能、服务状态和系统配置
- 借用OpenEuler系统验证应用功能：在OpenEuler虚拟机环境中验证应用程序的兼容性、功能完整性和执行效果，自动生成合适配置，启动系统，运行应用验证执行效果，最后关闭系统

## 快速开始

### 1. 启动虚拟机

```bash
cd scripts
./start_openeuler.sh [user|tap|config_file]
```

- `user`: 用户模式网络（默认，无需root）
- `tap`: TAP接口网络（需要root权限）
- `config_file`: 使用配置文件（如 `scenario1_config.sh`）

### 2. 访问虚拟机

**SSH访问**：
```bash
ssh -p <SSH_PORT> root@localhost
# 密码: openEuler12#$
```

> **注意**：首次登录时系统可能要求修改密码。如果SSH连接被拒绝，建议通过QEMU Monitor控制台登录（无需密码）。

**QEMU Monitor**：
```bash
telnet localhost <MONITOR_PORT>
# 按 Ctrl+] 退出Monitor
```

### 3. 停止虚拟机

```bash
./stop_openeuler.sh [instance_name]
```

- `instance_name`: 实例名称（如 `scenario1`），默认为 `default`

## 注意事项

### 环境限制

**在IDE沙箱/TraTerminal中运行：**
- ⚠️ **重要提醒**：由于沙箱环境的进程管理机制，启动脚本执行完成后，后台QEMU进程会被自动终止
- **解决方案**：请在真实Linux终端中执行脚本，或关闭沙箱后再运行
- 如果必须在沙箱中测试，脚本执行完成后QEMU进程将无法持续运行

**在真实终端中运行：**
- 正常情况下QEMU会持续运行，直到手动停止
- 可以通过SSH或Monitor连接进行交互
- 推荐使用真实终端以获得完整功能体验

### 首次登录

首次SSH登录时，系统可能要求修改密码。如果遇到权限问题，建议使用QEMU Monitor控制台登录（无需密码）：
```bash
telnet localhost <MONITOR_PORT>
# 按 Ctrl+] 退出，然后输入 quit
```

## 多实例配置

### 配置文件结构

每个实例使用独立的配置文件，实现资源隔离：

```
scripts/
├── default_config.sh      # 默认配置（单实例）
├── example_config.sh      # 示例配置
├── scenario1_config.sh    # 场景1配置
└── <your_scenario>_config.sh  # 自定义配置
```

### 配置文件示例

```bash
# 实例配置
INSTANCE_NAME="scenario1"
INSTANCE_ID="3"

# 资源路径
IMAGE_DIR="/home/volcano/myws/oee2403/build/qemu-aarch64/output/20260127163708"
KERNEL_PATH="$IMAGE_DIR/zImage"
ROOTFS_PATH="/home/volcano/myws/oee2403/build/qemu-aarch64/tmp/deploy/images/qemu-aarch64/openeuler-image-qemu-aarch64.cpio.gz"
DISK_IMG="/home/volcano/myws/oee2403/qemu_oee/scenario1_disk.img"

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

### 启动不同实例

```bash
# 使用默认配置启动
./start_openeuler.sh user

# 使用自定义配置启动
./start_openeuler.sh scenario1_config.sh

# 停止特定实例
./stop_openeuler.sh scenario1
```

## 目录结构

```
run_oee_qemu/
└── scripts/
    ├── start_openeuler.sh         # 启动脚本（主入口）
    ├── stop_openeuler.sh          # 停止脚本
    ├── qemu-ifup                  # TAP网络配置脚本
    ├── default_config.sh          # 默认配置文件
    ├── example_config.sh          # 示例配置文件
    ├── scenario1_config.sh        # 场景1配置文件
    ├── <instance>_config.sh       # 自定义配置文件
    ├── <instance>_disk.img        # 持久存储磁盘镜像（qcow2）
    ├── <instance>_qemu.pid        # QEMU进程ID文件
    └── <instance>_qemu.log        # QEMU运行日志
```

## 配置说明

### 硬件配置
- 机器类型: virt (ARM64通用平台)
- CPU: cortex-a53
- 核心数: 可配置（默认2核）
- 内存: 可配置（默认1024MB）

### 网络配置
- **用户模式**: 自动NAT，端口转发
- **TAP模式**: 桥接到br0，直接网络访问

### 端口映射
- Host `<SSH_PORT>` → Guest 22 (SSH)
- Host `<HTTP_PORT>` → Guest 80 (HTTP)
- Host `<MONITOR_PORT>` → QEMU Monitor

### 存储配置
- 根文件系统: initramfs (只读)
- 持久存储: /dev/vda (2GB qcow2)

## 详细文档

- **配置说明**: See [configuration.md](references/configuration.md) for detailed hardware, network, and storage configuration
- **故障排除**: 常见问题和解决方案

## 故障排除

### 1. 端口占用

**问题**：启动时报错 "端口被占用"

**解决方案**：
- 脚本会在启动前自动检查端口是否被占用
- 如果端口被占用，会显示占用进程的PID
- 使用 `./stop_openeuler.sh` 停止现有实例，或修改配置文件中的端口

```bash
# 手动检查端口占用
ss -tlnp | grep -E '2222|4444|8080'

# 停止现有实例
./stop_openeuler.sh default

# 或强制终止QEMU进程
pkill -9 -f qemu-system-aarch64
```

### 2. 首次登录需要修改密码

**问题**：首次SSH登录时系统强制要求修改密码，导致自动化脚本无法执行

**解决方案**：
- 使用 `--guest-os-info` 或 `-g` 参数，脚本会使用 `expect` 自动处理密码修改
- expect脚本会自动识别 "New password:" 和 "password:" 两种提示

```bash
# 启动并自动获取版本信息（自动处理密码修改）
./start_openeuler.sh user -g
```

### 3. 获取Guest OS版本信息

**问题**：需要自动获取虚拟机内的系统版本信息

**解决方案**：
- 使用 `-g` 或 `--guest-os-info` 参数
- 脚本使用 `expect` 自动登录并执行 `uname -a` 和 `cat /etc/os-release`

```bash
./start_openeuler.sh user -g

# 输出示例：
# === 系统版本信息 ===
# Linux qemu-aarch64 5.10.0-openeuler #1 SMP PREEMPT ...
# ID=openeuler
# NAME="openEuler Embedded(openEuler Embedded Reference Distro)"
# VERSION="24.03-LTS (openEuler24_03-LTS)"
```

### 4. 缺少磁盘镜像
```bash
qemu-img create -f qcow2 scripts/<instance>_disk.img 2G
```

### 5. SSH主机密钥变更
```bash
ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:<SSH_PORT>'
```

### 6. 查看日志
```bash
tail -f scripts/<instance>_qemu.log
```

### 7. 多实例端口冲突

确保每个实例的配置文件中使用不同的端口：
- `SSH_PORT` (默认2222)
- `HTTP_PORT` (默认8080)
- `MONITOR_PORT` (默认4444)

## 命令行参数

### start_openeuler.sh

启动openEuler嵌入式系统QEMU虚拟机的主脚本。

**功能概述：**
- 自动检查端口占用情况，避免冲突
- 支持用户模式和TAP模式两种网络配置
- 支持多实例运行，每个实例独立配置
- 自动生成QEMU启动参数并后台运行
- 可选自动获取Guest OS版本信息
- 提供详细的调试信息输出

**工作流程：**
1. 解析命令行参数
2. 加载配置文件（默认或指定）
3. 检查必要文件是否存在（内核、根文件系统等）
4. **启动前端口检查** - 检测端口是否被占用
5. 构建QEMU启动参数并启动虚拟机
6. **启动后端口检查** - 验证端口是否正常监听
7. 查找并验证QEMU进程
8. （可选）获取Guest OS版本信息

**使用方法：**

```bash
./start_openeuler.sh [user|tap|config_file] [--persistent] [--verbose] [--guest-os-info]
```

**参数说明：**

| 参数 | 说明 |
|------|------|
| `user` | 使用用户模式网络（默认），无需root权限，自动NAT |
| `tap` | 使用TAP接口网络，需要root权限，可直接访问网络 |
| `config_file` | 使用指定配置文件启动实例 |
| `--persistent` | 启用持久化存储，数据保存在qcow2磁盘镜像中 |
| `--verbose, -v` | 显示详细调试信息，包括完整的expect交互输出 |
| `--guest-os-info, -g` | 启动后自动获取并显示Guest OS版本信息 |

**使用示例：**

```bash
# 基本启动（用户模式网络）
./start_openeuler.sh user

# 启动并显示版本信息
./start_openeuler.sh user -g

# 启动并显示详细调试信息
./start_openeuler.sh user -g -v

# 使用自定义配置启动
./start_openeuler.sh scenario1_config.sh

# 启用持久化存储
./start_openeuler.sh user --persistent

# 使用TAP网络模式（需要root）
sudo ./start_openeuler.sh tap
```

**输出说明：**

```
启动openEuler QEMU虚拟机...
  实例: default                    # 实例名称
  配置: /path/to/config.sh         # 配置文件路径

=== 启动前端口检查 ===
[OK] 端口 2222 可用               # SSH端口
[OK] 端口 4444 可用               # Monitor端口
[OK] 端口 8080 可用               # HTTP端口

=== 启动后端口检查 ===
[OK] 端口 2222 已监听 (PID: 1234)  # 端口正常监听
[OK] 端口 4444 已监听 (PID: 1234)
[OK] 端口 8080 已监听 (PID: 1234)

QEMU运行中，PID: 1234              # QEMU进程ID
停止: /path/to/stop_openeuler.sh default  # 停止命令

=== Guest OS 已启动 ===            # 使用 -g 参数时显示
等待SSH服务就绪...
获取系统版本信息...

=== 系统版本信息 ===
Linux qemu-aarch64 5.10.0-openeuler ...
ID=openeuler
NAME="openEuler Embedded..."
VERSION="24.03-LTS..."
```

**错误处理：**

- 端口被占用时，显示占用进程PID并退出
- 配置文件不存在时，提示创建方法
- 内核/根文件系统缺失时，提示文件路径
- QEMU启动失败时，显示诊断信息和日志

### stop_openeuler.sh

```bash
./stop_openeuler.sh [instance_name]
```

| 参数 | 说明 |
|------|------|
| `instance_name` | 实例名称，默认为 `default` |