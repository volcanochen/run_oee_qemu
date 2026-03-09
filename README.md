# openEuler QEMU 虚拟机启动工具

启动openEuler嵌入式系统QEMU虚拟机，支持用户模式网络和TAP接口网络，包含持久存储、端口转发、QEMU Monitor访问、网络检查等功能。

**遇到问题？** 请参考 [故障排除文档](references/troubleshooting.md) 获取详细的解决方案。

## 功能特性

- ✅ 自动检查端口占用情况，避免冲突
- ✅ 支持用户模式和TAP模式两种网络配置
- ✅ 支持多实例运行，每个实例独立配置
- ✅ 自动生成QEMU启动参数并后台运行
- ✅ 可选自动获取Guest OS版本信息
- ✅ 提供详细的调试信息输出
- ✅ 自动处理首次登录密码修改
- ✅ 支持SSH密码交互自动化（密码过期场景）
- ✅ 支持Guest OS网络检查功能

## 快速开始

### 前置要求

- QEMU (qemu-system-aarch64)
- expect (用于自动登录)
- openEuler Embedded 内核和根文件系统

### 安装

```bash
git clone https://github.com/volcanochen/run_oee_qemu.git
cd run_oee_qemu/scripts
```

### 配置

编辑 `default_config.sh` 配置文件：

```bash
# 资源路径
KERNEL_PATH="/path/to/zImage"
ROOTFS_PATH="/path/to/openeuler-image-qemu-aarch64.cpio.gz"

# 网络端口
SSH_PORT=2222
HTTP_PORT=8080
MONITOR_PORT=4444

# 硬件配置
CPU_CORES=2
MEMORY_SIZE=1024
```

### 启动虚拟机

```bash
# 基本启动
./start_openeuler.sh user

# 启动并显示版本信息
./start_openeuler.sh user -g

# 启动并显示详细调试信息
./start_openeuler.sh user -g -v

# 启动并检查网络配置
./start_openeuler.sh user -n

# 启动并同时检查网络和显示版本
./start_openeuler.sh user -g -n
```

### 访问虚拟机

**SSH访问：**
```bash
ssh -p 2222 root@localhost
# 密码: openEuler12#$
```

**QEMU Monitor：**
```bash
telnet localhost 4444
```

### 停止虚拟机

```bash
./stop_openeuler.sh default
```

### 网络检查

使用 `ssh_guest_check.sh` 脚本检查Guest OS网络配置：

```bash
# 基本使用
./ssh_guest_check.sh

# 自定义参数
./ssh_guest_check.sh 2222 60
```

该脚本会自动：
1. 处理SSH密码过期场景（自动修改密码）
2. 执行网络检查命令（ping、curl、nslookup等）
3. 显示网络配置信息

### 持久性测试

使用持久性测试脚本验证QEMU虚拟机的持久化存储功能：

```bash
# 1. 启动虚拟机（启用持久化存储）
./start_openeuler.sh user --persistent

# 2. 设置持久化磁盘（格式化并挂载）
./setup_persistence_final.exp

# 3. 停止虚拟机
./stop_openeuler.sh default

# 4. 重新启动虚拟机
./start_openeuler.sh user --persistent

# 5. 验证数据是否保留
./verify_persistence.exp
```

**测试脚本说明**：

| 脚本 | 功能 | 使用场景 |
|------|------|----------|
| `setup_persistence_final.exp` | 持久化磁盘设置 | 首次使用时格式化并挂载磁盘（推荐） |
| `verify_persistence.exp` | 持久性验证 | 验证数据在重启后是否保留 |
| `check_qemu.exp` | QEMU状态检查 | 检查QEMU运行状态和磁盘信息 |
| `setup_persistence_v2.exp` | 持久化设置（密码过期处理） | 处理SSH密码过期场景 |

## 使用示例

### 输出示例

```
启动openEuler QEMU虚拟机...
  实例: default
  配置: /path/to/config.sh

=== 启动前端口检查 ===
[OK] 端口 2222 可用
[OK] 端口 4444 可用
[OK] 端口 8080 可用

=== 启动后端口检查 ===
[OK] 端口 2222 已监听 (PID: 1234)
[OK] 端口 4444 已监听 (PID: 1234)
[OK] 端口 8080 已监听 (PID: 1234)

QEMU运行中，PID: 1234
停止: /path/to/stop_openeuler.sh default

=== Guest OS 已启动 ===
等待SSH服务就绪...
获取系统版本信息...

=== 系统版本信息 ===
Linux qemu-aarch64 5.10.0-openeuler #1 SMP PREEMPT Wed Jul 17 09:57:37 UTC 2024 aarch64 aarch64 aarch64 GNU/Linux
ID=openeuler
NAME="openEuler Embedded(openEuler Embedded Reference Distro)"
VERSION="24.03-LTS (openEuler24_03-LTS)"
PRETTY_NAME="openEuler Embedded(openEuler Embedded Reference Distro) 24.03-LTS (openEuler24_03-LTS)"
```

### 网络检查输出示例

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

## 命令行参数

### start_openeuler.sh

```bash
./start_openeuler.sh [user|tap|config_file] [--persistent] [--verbose] [--guest-os-info] [--check-network]
```

| 参数 | 说明 |
|------|------|
| `user` | 使用用户模式网络（默认），无需root权限 |
| `tap` | 使用TAP接口网络，需要root权限 |
| `config_file` | 使用指定配置文件启动实例 |
| `--persistent` | 启用持久化存储 |
| `--verbose, -v` | 显示详细调试信息 |
| `--guest-os-info, -g` | 启动后自动获取Guest OS版本信息 |
| `--check-network, -n` | 启动后自动检查Guest OS网络配置 |

### stop_openeuler.sh

```bash
./stop_openeuler.sh [instance_name]
```

| 参数 | 说明 |
|------|------|
| `instance_name` | 实例名称，默认为 `default` |

### ssh_guest_check.sh

```bash
./ssh_guest_check.sh [ssh_port] [timeout]
```

| 参数 | 说明 |
|------|------|
| `ssh_port` | SSH端口，默认为 2222 |
| `timeout` | 超时时间（秒），默认为 60 |

## 多实例配置

每个实例使用独立的配置文件：

```bash
scripts/
├── default_config.sh      # 默认配置
├── scenario1_config.sh    # 场景1配置
└── <your_scenario>_config.sh  # 自定义配置
```

启动不同实例：

```bash
./start_openeuler.sh scenario1_config.sh
./stop_openeuler.sh scenario1
```

## 故障排除

详细的问题诊断和解决方案，请参考 [故障排除文档](references/troubleshooting.md)。

### 常见问题快速参考

| 问题 | 快速解决方案 | 详细文档 |
|------|------------|----------|
| 端口占用 | `./stop_openeuler.sh default` | [故障排除文档](references/troubleshooting.md) |
| 首次登录密码修改 | `./start_openeuler.sh user -g` | [SSH访问指南](references/ssh_access.md) |
| SSH连接超时 | 检查QEMU运行状态和端口 | [SSH访问指南](references/ssh_access.md) |
| 持久化存储问题 | 使用 `setup_persistence_final.exp` 和 `verify_persistence.exp` | [故障排除文档](references/troubleshooting.md) |

### 端口占用

```bash
# 检查端口占用
ss -tlnp | grep -E '2222|4444|8080'

# 停止现有实例
./stop_openeuler.sh default
```

### 首次登录需要修改密码

使用 `-g` 参数，脚本会自动处理密码修改：

```bash
./start_openeuler.sh user -g
```

### 查看日志

```bash
tail -f scripts/default_qemu.log
```

### 网络检查失败

如果网络检查失败，请检查：
1. QEMU是否正常运行
2. SSH服务是否启动
3. 网络配置是否正确

## 目录结构

```
run_oee_qemu/
├── README.md                   # 本文件
├── SKILL.md                    # 详细文档
├── .gitignore                  # Git忽略配置
└── references/                   # 详细文档目录
    ├── ssh_access.md             # SSH访问指南
    ├── configuration.md         # 配置说明
    ├── multi_instance.md        # 多实例配置指南
    └── troubleshooting.md      # 故障排除文档
scripts/
├── start_openeuler.sh      # 启动脚本（核心）
├── stop_openeuler.sh       # 停止脚本（核心）
├── qemu-ifup               # TAP网络配置（核心）
├── default_config.sh       # 默认配置（核心）
├── example_config.sh      # 示例配置（参考）
├── scenario1_config.sh    # 场景1配置（参考）
├── ssh_guest_check.sh     # 网络检查脚本（工具）
├── check_network.sh       # 网络检查辅助（工具）
├── setup_persistence_final.exp  # 持久化设置（推荐）
├── verify_persistence.exp # 持久性验证（推荐）
├── <instance>_disk.img     # 持久存储镜像（运行时生成）
├── <instance>_qemu.pid     # 进程ID文件（运行时生成）
└── <instance>_qemu.log     # 运行日志（运行时生成）
```

## 详细文档

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

## 文件管理说明

### 核心文件（必须版本管理）

以下文件是工具的核心组件，**必须**纳入版本管理：

| 文件 | 说明 | 重要性 |
|------|------|--------|
| `start_openeuler.sh` | QEMU虚拟机启动脚本 | ⭐⭐⭐ |
| `stop_openeuler.sh` | QEMU虚拟机停止脚本 | ⭐⭐⭐ |
| `qemu-ifup` | TAP网络配置脚本 | ⭐⭐⭐ |
| `default_config.sh` | 默认配置文件 | ⭐⭐⭐ |
| `ssh_guest_check.sh` | SSH网络检查脚本 | ⭐⭐ |
| `check_network.sh` | 网络检查辅助脚本 | ⭐⭐ |

### 参考配置文件（建议版本管理）

以下文件是配置示例，**建议**纳入版本管理：

| 文件 | 说明 | 重要性 |
|------|------|--------|
| `example_config.sh` | 配置文件示例 | ⭐⭐ |
| `scenario1_config.sh` | 场景1配置示例 | ⭐ |

### 验证测试脚本（可选版本管理）

以下脚本用于功能验证和持久性测试，**可选**纳入版本管理：

| 文件 | 说明 | 用途 |
|------|------|------|
| `test_persistence.exp` | 持久性基础测试 | 验证持久化功能 |
| `setup_persistence_final.exp` | 持久化磁盘设置 | 格式化并挂载持久化磁盘 |
| `verify_persistence.exp` | 持久性验证 | 验证数据在重启后是否保留 |
| `check_qemu.exp` | QEMU状态检查 | 检查QEMU运行状态 |
| `setup_and_test_persistence.exp` | 持久化完整测试 | 完整的持久化测试流程 |
| `setup_persistence_v2.exp` | 持久化测试v2 | 持久化测试变体 |
| `setup_persistence_v3.exp` | 持久化测试v3 | 持久化测试变体 |

**使用场景**：
- 验证QEMU虚拟机的持久化存储功能
- 测试驱动程序或应用程序的数据持久性
- 回归测试和功能验证

### 运行时生成文件（不纳入版本管理）

以下文件在运行时自动生成，**不应**纳入版本管理（已在.gitignore中配置）：

| 文件模式 | 说明 | 生成时机 |
|----------|------|----------|
| `*_disk.img` | 持久存储磁盘镜像 | 首次启动时自动创建 |
| `*_qemu.pid` | QEMU进程ID文件 | 启动时生成，停止时删除 |
| `*_qemu.log` | QEMU运行日志 | 运行时持续写入 |

### 版本管理建议

1. **核心文件**：始终纳入Git版本控制
2. **配置文件**：纳入版本控制，但敏感信息（如密码）应使用环境变量
3. **测试脚本**：根据团队需求决定是否纳入版本控制
4. **运行时文件**：使用.gitignore排除，避免提交大文件和临时文件

### .gitignore 配置

```gitignore
# QEMU runtime files
*_disk.img
*_qemu.log
*_qemu.pid

# Temporary test files (keep for persistence testing)
# 如需排除测试脚本，取消以下注释
# test_persistence.exp
# setup_persistence_final.exp
# verify_persistence.exp
# check_qemu.exp
# setup_and_test_persistence.exp
# setup_persistence_v2.exp
# setup_persistence_v3.exp
```

## 注意事项

### 环境限制

⚠️ **重要提醒**：在IDE沙箱/TraTerminal中运行时，后台QEMU进程会被自动终止。

**解决方案**：请在真实Linux终端中执行脚本。

### 网络检查

- 网络检查脚本会自动处理SSH密码过期场景
- 支持自定义网络检查命令
- 可复用 `ssh_password_expect()` 函数处理密码交互

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
