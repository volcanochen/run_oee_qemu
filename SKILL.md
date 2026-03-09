---
name: run-oee-qemu
description: 启动和管理openEuler嵌入式系统QEMU虚拟机，支持用户模式网络和TAP接口网络，包含持久存储、端口转发、QEMU Monitor访问、多实例隔离、网络检查等功能。使用场景包括：(1) 开发和测试openEuler嵌入式系统，(2) 验证内核修改和驱动程序，(3) 网络服务开发和调试，(4) 系统性能测试，(5) 多实例隔离测试，(6) 验证OpenEuler系统功能（快速验证基本功能、服务状态和系统配置），(7) 在OpenEuler虚拟机环境中验证应用程序的兼容性、功能完整性和执行效果（自动生成合适配置，启动系统，运行应用验证执行效果，最后关闭系统），(8) 自动化Guest OS网络检查（SSH密码交互、网络连通性测试、DNS解析验证）
---

# openEuler QEMU虚拟机启动

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

> **注意**：首次登录时系统可能要求修改密码。请参考"首次登录"部分了解如何正确处理密码验证。

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

### 4. 网络检查

使用 `ssh_guest_check.sh` 脚本检查Guest OS网络配置：

```bash
./ssh_guest_check.sh
```

该脚本会自动：
1. 处理SSH密码过期场景（自动修改密码）
2. 执行网络检查命令（ping、curl、nslookup等）
3. 显示网络配置信息

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

首次SSH登录时，系统可能要求修改密码。系统会显示 "(root@localhost) Password:" 或 "password:" 提示。

**解决方案**：

1. **使用自动化参数**（推荐）：
   ```bash
   ./start_openeuler.sh user -g
   ```
   脚本会自动使用 expect 处理密码验证和修改。

2. **使用 ssh_guest_check.sh**（推荐用于网络检查）：
   ```bash
   ./ssh_guest_check.sh
   ```
   该脚本会自动处理密码交互并执行网络检查。

3. **手动使用 expect 处理**：
   ```bash
   expect -c '
   set timeout 60
   spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost
   expect {
       "New password:" {
           send "openEuler12#$\r"
           expect "Retype new password:"
           send "openEuler12#$\r"
           expect "#"
       }
       "(root@localhost) Password:" {
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
   send "exit\r"
   expect eof
   '
   ```

4. **使用 QEMU Monitor 登录**（无需密码）：
   ```bash
   telnet localhost <MONITOR_PORT>
   # 按 Ctrl+] 退出，然后输入 quit
   ```

### SSH 访问脚本示例

**自动处理密码验证和修改的完整脚本**：

```bash
#!/bin/bash
# SSH 访问脚本 - 自动处理密码验证

SSH_PORT=${1:-2222}
TIMEOUT=${2:-60}

expect -c "
set timeout $TIMEOUT
spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSH_PORT root@localhost
expect {
    \"New password:\" {
        send \"openEuler12#\$\\r\"
        expect \"Retype new password:\"
        send \"openEuler12#\$\\r\"
        expect \"#\"
    }
    \"(root@localhost) Password:\" {
        send \"openEuler12#\$\\r\"
        expect \"#\"
    }
    \"password:\" {
        send \"openEuler12#\$\\r\"
        expect \"#\"
    }
    \"#\" {}
    timeout {
        puts \"ERROR: SSH connection timeout\"
        exit 1
    }
}
send \"uname -a\\r\"
expect \"#\"
send \"cat /etc/os-release\\r\"
expect \"#\"
send \"ip addr show\\r\"
expect \"#\"
send \"netstat -tlnp\\r\"
expect \"#\"
send \"exit\\r\"
expect eof
"
```

**使用方法**：
```bash
./ssh_access.sh [SSH_PORT] [TIMEOUT]
# 默认: SSH_PORT=2222, TIMEOUT=60
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
    ├── ssh_guest_check.sh         # 网络检查脚本
    ├── check_network.sh           # 网络检查辅助脚本
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
- **故障排除**: See [troubleshooting.md](references/troubleshooting.md) for common issues and solutions

## 命令行参数

### start_openeuler.sh

启动openEuler嵌入式系统QEMU虚拟机的主脚本。

**功能概述：**
- 自动检查端口占用情况，避免冲突
- 支持用户模式和TAP模式两种网络配置
- 支持多实例运行，每个实例独立配置
- 自动生成QEMU启动参数并后台运行
- 可选自动获取Guest OS版本信息
- 可选自动检查Guest OS网络配置
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
9. （可选）执行Guest OS网络检查

**使用方法：**

```bash
./start_openeuler.sh [user|tap|config_file] [--persistent] [--verbose] [--guest-os-info] [--check-network]
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
| `--check-network, -n` | 启动后自动检查Guest OS网络配置 |

**使用示例：**

```bash
# 基本启动（用户模式网络）
./start_openeuler.sh user

# 启动并显示版本信息
./start_openeuler.sh user -g

# 启动并显示详细调试信息
./start_openeuler.sh user -g -v

# 启动并检查网络配置
./start_openeuler.sh user -n

# 启动并同时检查网络和显示版本
./start_openeuler.sh user -g -n

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

=== 网络检查 ===                   # 使用 -n 参数时显示
=== openEuler Guest OS 网络检查 ===
SSH 端口: 2222

=== 处理密码交互 ===
尝试 1/3: 连接 SSH...
✓ 密码交互成功

=== 执行网络检查 ===
尝试 1/3: 连接 SSH...
✓ 网络检查成功
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

### ssh_guest_check.sh

自动检查Guest OS网络配置的脚本。

**功能概述：**
- 自动处理SSH密码过期场景（旧密码->新密码->确认新密码）
- 执行网络检查命令（ping、curl、nslookup等）
- 显示网络配置信息（DNS、路由、端口等）

**使用方法：**

```bash
./ssh_guest_check.sh [ssh_port] [timeout]
```

| 参数 | 说明 |
|------|------|
| `ssh_port` | SSH端口，默认为 2222 |
| `timeout` | 超时时间（秒），默认为 60 |

**使用示例：**

```bash
# 基本使用（默认参数）
./ssh_guest_check.sh

# 自定义端口和超时
./ssh_guest_check.sh 2222 60
```

**输出示例：**

```
=== openEuler Guest OS 网络检查 ===
SSH 端口: 2222

=== 处理密码交互 ===
尝试 1/3: 连接 SSH...
✓ 密码交互成功

=== 执行网络检查 ===
尝试 1/3: 连接 SSH...
✓ 网络检查成功
```

**可复用函数：**

脚本提供了 `ssh_password_expect()` 函数，可被其他脚本复用：

```bash
# 只处理密码交互
ssh_password_expect 2222 60 "oldpass" "newpass"

# 处理密码并执行命令
ssh_password_expect 2222 60 "oldpass" "newpass" "echo SSH_OK; uname -a"
```
