# openEuler QEMU虚拟机故障排除

## 常见问题和解决方案

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

**问题现象**：
- 登录时显示 "(root@localhost) Password:" 或 "password:" 提示
- 系统要求输入初始密码 `openEuler12#$`
- 如果直接输入密码，系统会要求修改密码

**解决方案**：
- 使用 `--guest-os-info` 或 `-g` 参数，脚本会使用 `expect` 自动处理密码修改
- expect脚本会自动识别以下提示并自动处理：
  - "New password:" - 首次设置密码
  - "(root@localhost) Password:" - 密码验证提示
  - "password:" - 通用密码提示

**自动化脚本示例**：

```bash
# 启动并自动获取版本信息（自动处理密码修改）
./start_openeuler.sh user -g

# 或使用expect手动处理
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

**问题**：启动时报错 "找不到持久存储磁盘镜像"

**解决方案**：

```bash
# 创建2GB的qcow2磁盘镜像
qemu-img create -f qcow2 scripts/<instance>_disk.img 2G

# 示例：为default实例创建磁盘
qemu-img create -f qcow2 scripts/default_disk.img 2G
```

### 5. SSH主机密钥变更

**问题**：SSH连接时报错 "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"

**解决方案**：

```bash
# 删除特定端口的known_hosts条目
ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:<SSH_PORT>'

# 示例：删除2222端口的条目
ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:2222'
```

### 6. 查看日志

**问题**：需要查看QEMU虚拟机的运行日志

**解决方案**：

```bash
# 实时查看日志
tail -f scripts/<instance>_qemu.log

# 查看最后100行
tail -n 100 scripts/<instance>_qemu.log

# 查看完整日志
cat scripts/<instance>_qemu.log
```

### 7. 多实例端口冲突

**问题**：启动多个实例时端口冲突

**解决方案**：
确保每个实例的配置文件中使用不同的端口：
- `SSH_PORT` (默认2222)
- `HTTP_PORT` (默认8080)
- `MONITOR_PORT` (默认4444)

**示例配置**：

```bash
# instance1_config.sh
SSH_PORT=2222
HTTP_PORT=8080
MONITOR_PORT=4444

# instance2_config.sh
SSH_PORT=2223
HTTP_PORT=8081
MONITOR_PORT=4445

# instance3_config.sh
SSH_PORT=2224
HTTP_PORT=8082
MONITOR_PORT=4446
```

### 8. QEMU进程无法启动

**问题**：脚本执行后QEMU进程立即退出

**可能原因和解决方案**：

1. **内核文件路径错误**
   ```bash
   # 检查内核文件是否存在
   ls -l /path/to/zImage
   ```

2. **根文件系统路径错误**
   ```bash
   # 检查根文件系统是否存在
   ls -l /path/to/openeuler-image-qemu-aarch64.cpio.gz
   ```

3. **QEMU二进制文件不存在**
   ```bash
   # 检查QEMU是否安装
   which qemu-system-aarch64
   ```

4. **权限不足**
   ```bash
   # 确保脚本有执行权限
   chmod +x scripts/start_openeuler.sh
   ```

### 9. SSH连接超时

**问题**：SSH连接时提示 "Connection timed out"

**解决方案**：

1. **等待虚拟机完全启动**
   ```bash
   # 查看QEMU日志确认系统已启动
   tail -f scripts/<instance>_qemu.log
   ```

2. **检查SSH服务是否运行**
   ```bash
   # 通过QEMU Monitor检查系统状态
   telnet localhost <MONITOR_PORT>
   # 输入: info status
   ```

3. **检查端口转发是否正确**
   ```bash
   # 检查SSH端口是否在监听
   ss -tlnp | grep <SSH_PORT>
   ```

### 10. 网络连接问题

**问题**：虚拟机内无法访问外部网络

**解决方案**：

1. **用户模式网络检查**
   ```bash
   # 在虚拟机内检查网络配置
   ip addr show
   ip route
   cat /etc/resolv.conf

   # 测试DNS解析
   ping 8.8.8.8
   ```

2. **TAP模式网络检查**
   ```bash
   # 在主机上检查网桥
   brctl show
   ip addr show br0

   # 检查TAP接口
   ip addr show tap0
   ```

3. **防火墙问题**
   ```bash
   # 检查防火墙规则
   sudo iptables -L -n
   ```

### 11. 磁盘空间不足

**问题**：虚拟机内磁盘空间不足

**解决方案**：

```bash
# 在虚拟机内检查磁盘使用情况
df -h

# 扩展磁盘镜像（需要先关闭虚拟机）
qemu-img resize scripts/<instance>_disk.img +1G

# 在虚拟机内扩展分区和文件系统
# 具体步骤取决于使用的文件系统类型
```

### 12. 虚拟机性能问题

**问题**：虚拟机运行缓慢

**解决方案**：

1. **增加CPU核心数**
   ```bash
   # 在配置文件中修改
   CPU_CORES=4
   ```

2. **增加内存**
   ```bash
   # 在配置文件中修改
   MEMORY_SIZE=2048
   ```

3. **启用KVM加速**
   ```bash
   # 修改启动参数，添加 -enable-kvm
   # 注意：需要硬件虚拟化支持
   ```

### 13. QEMU Monitor无法连接

**问题**：telnet连接QEMU Monitor失败

**解决方案**：

```bash
# 检查Monitor端口是否在监听
ss -tlnp | grep <MONITOR_PORT>

# 检查QEMU进程是否运行
ps aux | grep qemu-system-aarch64

# 尝试重新连接
telnet localhost <MONITOR_PORT>
```

### 14. 数据持久化问题

**问题**：虚拟机关闭后数据丢失

**解决方案**：

1. **确认启用了持久化存储**
   ```bash
   # 使用 --persistent 参数启动
   ./start_openeuler.sh user --persistent
   ```

2. **在虚拟机内挂载磁盘**
   ```bash
   # 查看磁盘
   lsblk

   # 分区（如果需要）
   fdisk /dev/vda

   # 格式化
   mkfs.ext4 /dev/vda1

   # 挂载
   mount /dev/vda1 /mnt

   # 写入测试数据
   echo "test" > /mnt/test.txt
   ```

3. **验证数据持久化**
   ```bash
   # 关闭虚拟机
   ./stop_openeuler.sh <instance>

   # 重新启动
   ./start_openeuler.sh user --persistent

   # 检查数据是否还在
   cat /mnt/test.txt
   ```

## 调试技巧

### 启用详细日志

```bash
# 使用 --verbose 参数查看详细调试信息
./start_openeuler.sh user --verbose

# 或使用 -v 简写
./start_openeuler.sh user -v
```

### 检查进程状态

```bash
# 查看QEMU进程详细信息
ps aux | grep qemu-system-aarch64

# 查看进程树
pstree -p <PID>
```

### 检查网络连接

```bash
# 检查所有监听端口
ss -tlnp

# 检查特定端口
ss -tlnp | grep -E '2222|4444|8080'

# 测试SSH连接
ssh -v -p <SSH_PORT> root@localhost
```

### 检查磁盘镜像

```bash
# 查看磁盘镜像信息
qemu-img info scripts/<instance>_disk.img

# 检查磁盘镜像格式
file scripts/<instance>_disk.img
```

## 获取帮助

如果以上解决方案无法解决您的问题，请：

1. 查看QEMU日志文件获取详细错误信息
2. 使用 `--verbose` 参数重新启动并查看详细输出
3. 检查系统日志：`dmesg | grep -i qemu`
4. 参考QEMU官方文档：https://www.qemu.org/docs/master/
