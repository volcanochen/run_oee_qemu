# SSH访问指南

本文档详细说明如何通过SSH访问openEuler QEMU虚拟机。

## 基本SSH连接

```bash
ssh -p <SSH_PORT> root@localhost
# 默认端口: 2222
# 默认密码: openEuler12#$
```

## 首次登录密码处理

首次SSH登录时，系统可能要求修改密码。系统会显示以下提示之一：

- `(root@localhost) Password:` - 首次登录需要修改密码
- `New password:` - 输入新密码
- `Retype new password:` - 确认新密码
- `password:` - 普通密码提示

### 解决方案

#### 1. 使用自动化参数（推荐）

```bash
./start_openeuler.sh user -g
```

脚本会自动使用expect处理密码验证和修改。

#### 2. 使用ssh_guest_check.sh

```bash
./ssh_guest_check.sh
```

该脚本会自动处理密码交互并执行网络检查。

#### 3. 手动使用expect处理

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

#### 4. 使用QEMU Monitor（无需密码）

```bash
telnet localhost <MONITOR_PORT>
# 默认Monitor端口: 4444
# 按 Ctrl+] 退出，然后输入 quit
```

## SSH访问脚本示例

创建一个自动处理密码验证的完整脚本：

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

## 常用SSH命令

### 查看系统信息
```bash
uname -a                    # 内核版本
cat /etc/os-release         # 操作系统版本
```

### 网络配置
```bash
ip addr show                # 网络接口
ip route show              # 路由表
netstat -tlnp             # 监听端口
ping -c 4 8.8.8.8        # 测试网络连通性
```

### 磁盘和文件系统
```bash
df -h                      # 磁盘使用情况
lsblk                      # 块设备信息
mount                      # 挂载点信息
```

### 进程和系统
```bash
ps aux                     # 进程列表
top                        # 实时进程监控
free -h                    # 内存使用情况
```

## SSH配置优化

### 禁用主机密钥检查（测试环境）

在 `~/.ssh/config` 中添加：

```
Host localhost
    HostName localhost
    Port 2222
    User root
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### 使用SSH密钥认证（生产环境）

```bash
# 生成SSH密钥
ssh-keygen -t rsa -b 4096

# 复制公钥到虚拟机
ssh-copy-id -p 2222 root@localhost

# 之后可以无密码登录
ssh -p 2222 root@localhost
```

## 故障排除

### 连接超时

**问题**：SSH连接超时

**解决方案**：
1. 检查QEMU虚拟机是否正在运行
2. 检查端口是否正确：`netstat -tlnp | grep 2222`
3. 检查防火墙设置
4. 增加超时时间：`ssh -o ConnectTimeout=120 -p 2222 root@localhost`

### 密码错误

**问题**：密码认证失败

**解决方案**：
1. 确认密码是否正确：`openEuler12#$`
2. 检查是否需要修改密码（首次登录）
3. 使用expect脚本自动处理密码交互
4. 查看配置文件中的密码设置

### 主机密钥变更

**问题**：`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`

**解决方案**：
```bash
ssh-keygen -f ~/.ssh/known_hosts -R "[localhost]:2222"
```

## 相关文档

- [故障排除文档](troubleshooting.md) - 常见问题和解决方案
- [配置说明](configuration.md) - 网络和端口配置
