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

**遇到问题？** 请参考 [故障排除文档](references/troubleshooting.md) 获取详细的解决方案。

### 2. 访问虚拟机

**SSH访问**：
```bash
ssh -p <SSH_PORT> root@localhost
# 密码: openEuler12#$
```

> **注意**：首次登录时系统可能要求修改密码。请参考 [SSH访问指南](references/ssh_access.md) 了解如何正确处理密码验证。

**QEMU Monitor**：
```bash
telnet localhost <MONITOR_PORT>
# 按 Ctrl+] 退出Monitor
```

### 3. 停止虚拟机

```bash
./stop_openeuler.sh [instance_name|PID]
```

- `instance_name`: 实例名称（如 `scenario1`），默认为 `default`
- `PID`: 进程ID（如 `12345`）

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

3. **使用 QEMU Monitor 登录**（无需密码）：
   ```bash
   telnet localhost <MONITOR_PORT>
   # 按 Ctrl+] 退出，然后输入 quit
   ```

详细说明请参考 [SSH访问指南](references/ssh_access.md)。

## 目录结构

```
run_oee_qemu/
├── SKILL.md                      # 本文档
├── README.md                     # 项目说明
└── references/                   # 详细文档目录
    ├── ssh_access.md             # SSH访问指南
    ├── configuration.md         # 配置说明
    ├── multi_instance.md        # 多实例配置指南
    └── troubleshooting.md      # 故障排除文档
scripts/
├── start_openeuler.sh         # 启动脚本（主入口）
├── stop_openeuler.sh          # 停止脚本
├── qemu-ifup                 # TAP网络配置脚本
├── default_config.sh          # 默认配置文件
├── example_config.sh          # 示例配置文件
├── scenario1_config.sh        # 场景1配置文件
├── <instance>_config.sh       # 自定义配置文件
├── ssh_guest_check.sh        # 网络检查脚本
├── check_network.sh          # 网络检查辅助脚本
├── setup_persistence_final.exp  # 持久化磁盘设置脚本
├── verify_persistence.exp     # 持久性验证脚本
├── <instance>_disk.img       # 持久存储磁盘镜像（qcow2）
├── <instance>_qemu.pid       # QEMU进程ID文件
└── <instance>_qemu.log       # QEMU运行日志
```

## 详细文档索引

### 核心功能文档

- **[SSH访问指南](references/ssh_access.md)** - SSH连接、密码处理、常用命令、故障排除
- **[配置说明](references/configuration.md)** - 硬件配置、网络配置、存储配置、配置文件示例
- **[多实例配置指南](references/multi_instance.md)** - 多实例配置、端口规划、资源隔离、使用场景

### 故障排除文档

- **[故障排除文档](references/troubleshooting.md)** - 常见问题和解决方案，包括：
  - 端口冲突问题
  - SSH连接问题
  - 网络配置问题
  - 持久化存储问题
  - 多实例管理问题
  - IDE沙箱环境问题

## 命令行参数

### start_openeuler.sh

启动openEuler嵌入式系统QEMU虚拟机的主脚本。

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

# 启用持久化存储
./start_openeuler.sh user --persistent

# 使用自定义配置启动
./start_openeuler.sh scenario1_config.sh

# 使用TAP网络模式（需要root）
sudo ./start_openeuler.sh tap
```

**输出说明：**

```
启动openEuler QEMU虚拟机...
  实例: default
  配置: /path/to/config.sh  时间戳  MD5_hash
  持久化存储: 已启用 (/path/to/disk.img)  时间戳  MD5_hash

=== 启动前端口检查 ===
[OK] 端口 2222 可用
[OK] 端口 4444 可用
[OK] 端口 8080 可用

=== 启动后端口检查 ===
[OK] 端口 2222 已监听 (PID: 1234)
[OK] 端口 4444 已监听 (PID: 1234)
[OK] 端口 8080 已监听 (PID: 1234)

QEMU运行中，PID: 1234
停止命令: /path/to/stop_openeuler.sh default
停止命令: /path/to/stop_openeuler.sh 1234
```

### stop_openeuler.sh

停止QEMU虚拟机的脚本。

**使用方法：**

```bash
./stop_openeuler.sh [instance_name|PID]
```

**参数说明：**

| 参数 | 说明 |
|------|------|
| `instance_name` | 实例名称（如 `default`、`scenario1`），默认为 `default` |
| `PID` | 进程ID（如 `12345`），直接按PID停止 |

**使用示例：**

```bash
# 按实例名称停止
./stop_openeuler.sh default
./stop_openeuler.sh scenario1

# 按PID停止
./stop_openeuler.sh 12345
```

### ssh_guest_check.sh

自动检查Guest OS网络配置的脚本。

**使用方法：**

```bash
./ssh_guest_check.sh [ssh_port] [timeout]
```

**参数说明：**

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

## 配置概览

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

详细配置说明请参考 [配置说明](references/configuration.md)。

## 多实例配置

支持同时运行多个QEMU虚拟机实例，每个实例拥有独立的配置、资源和网络端口。

**基本用法：**

```bash
# 启动默认实例
./start_openeuler.sh user

# 启动场景1实例
./start_openeuler.sh scenario1_config.sh

# 停止特定实例
./stop_openeuler.sh scenario1
```

详细说明请参考 [多实例配置指南](references/multi_instance.md)。

## 常见问题

### QEMU进程在IDE沙箱中无法持续运行

**问题**：在IDE沙箱或TraTerminal中启动QEMU后，进程立即被终止。

**解决方案**：
- 在真实Linux终端中执行脚本
- 或关闭IDE沙箱后再运行

详细说明请参考 [故障排除文档](references/troubleshooting.md)。

### SSH连接超时

**问题**：无法SSH连接到虚拟机。

**解决方案**：
1. 检查QEMU虚拟机是否正在运行
2. 检查端口是否正确
3. 使用expect脚本自动处理密码交互
4. 查看虚拟机日志

详细说明请参考 [SSH访问指南](references/ssh_access.md) 和 [故障排除文档](references/troubleshooting.md)。

### 端口冲突

**问题**：启动时提示端口被占用。

**解决方案**：
1. 检查端口占用：`netstat -tlnp | grep <PORT>`
2. 停止占用进程：`kill <PID>`
3. 修改配置文件中的端口
4. 重新启动实例

详细说明请参考 [故障排除文档](references/troubleshooting.md)。

## 使用场景

### 场景1：开发和测试openEuler嵌入式系统

```bash
# 启动虚拟机
./start_openeuler.sh user

# SSH访问
ssh -p 2222 root@localhost

# 开发和测试...
# 停止虚拟机
./stop_openeuler.sh default
```

### 场景2：验证内核修改和驱动程序

```bash
# 启用持久化存储
./start_openeuler.sh user --persistent

# 加载新内核和驱动
# 验证功能
# 停止虚拟机
./stop_openeuler.sh default
```

### 场景3：网络服务开发和调试

```bash
# 启动虚拟机
./start_openeuler.sh user -n

# 脚本自动检查网络配置
# 开发和调试网络服务
# 停止虚拟机
./stop_openeuler.sh default
```

### 场景4：多实例隔离测试

```bash
# 终端1：启动实例1
./start_openeuler.sh scenario1_config.sh

# 终端2：启动实例2
./start_openeuler.sh scenario2_config.sh

# 并行测试多个场景
# 停止实例
./stop_openeuler.sh scenario1
./stop_openeuler.sh scenario2
```

详细使用场景请参考 [多实例配置指南](references/multi_instance.md)。

## 获取帮助

- **遇到问题？** 请参考 [故障排除文档](references/troubleshooting.md) 获取详细的解决方案
- **SSH访问问题** 请参考 [SSH访问指南](references/ssh_access.md)
- **配置问题** 请参考 [配置说明](references/configuration.md)
- **多实例管理** 请参考 [多实例配置指南](references/multi_instance.md)
