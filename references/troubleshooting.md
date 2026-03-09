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

## 持久性测试

### 快速开始

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

### 测试脚本说明

| 脚本 | 功能 | 使用场景 |
|------|------|----------|
| `setup_persistence_final.exp` | 持久化磁盘设置 | 首次使用时格式化并挂载磁盘（推荐） |
| `verify_persistence.exp` | 持久性验证 | 验证数据在重启后是否保留 |
| `check_qemu.exp` | QEMU状态检查 | 检查QEMU运行状态和磁盘信息 |
| `setup_persistence_v2.exp` | 持久化设置（密码过期处理） | 处理SSH密码过期场景 |

### setup_persistence_final.exp

**功能**：
- 简单的SSH密码处理（2种场景）
- 查看块设备信息（`lsblk`）
- 格式化持久化磁盘为ext4文件系统
- 创建挂载点目录（`/mnt/persistent`）
- 挂载持久化磁盘
- 创建测试文件并写入时间戳
- 同步文件系统

**使用方法**：
```bash
./setup_persistence_final.exp
```

**输出示例**：
```
qemu-aarch64 ~ # lsblk
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
vda     254:0    0   2G  0 disk 

qemu-aarch64 ~ # mkfs.ext4 /dev/vda
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 524288 4k blocks and 131072 inodes
Filesystem UUID: 066889f0-f792-4cf8-8aa6-41d742645de1

qemu-aarch64 ~ # mount /dev/vda /mnt/persistent
qemu-aarch64 ~ # df -h | grep vda
/dev/vda        2.0G   24K  1.8G   1% /mnt/persistent

qemu-aarch64 ~ # echo 'Persistence Test - First Run - ' $(date) > /mnt/persistent/test_persistence.txt
Persistence Test - First Run -  Thu Jan 1 00:00:32 UTC 1970
```

### verify_persistence.exp

**功能**：
- 挂载持久化磁盘
- 显示之前创建的测试文件内容（验证数据是否保留）
- 追加第二次运行数据到测试文件
- 显示更新后的测试文件内容（包含第一次和第二次的数据）

**使用方法**：
```bash
./verify_persistence.exp
```

**输出示例**：
```
qemu-aarch64 ~ # cat /mnt/persistent/test_persistence.txt
Persistence Test - First Run -  Thu Jan 1 00:00:32 UTC 1970

qemu-aarch64 ~ # echo 'Persistence Test - Second Run - ' $(date) >> /mnt/persistence/test_persistence.txt
qemu-aarch64 ~ # cat /mnt/persistence/test_persistence.txt
Persistence Test - First Run -  Thu Jan 1 00:00:32 UTC 1970
Persistence Test - Second Run -  Thu Jan 1 00:00:20 UTC 1970
```

**验证成功标志**：第一次运行的数据在重启后完整保留！

### check_qemu.exp

**功能**：
- 通过QEMU Monitor检查虚拟机运行状态
- 检查块设备信息（包括持久化磁盘）
- 自动退出Monitor

**使用方法**：
```bash
./check_qemu.exp
```

**输出示例**：
```
VM status: running
virtio0 (#block194): /home/volcano/myws/skills/run_oee_qemu/scripts/default_disk.img (qcow2)
```

### setup_persistence_v2.exp

**功能**：
- 自动处理SSH密码过期场景（5种密码提示）
- 查看块设备信息（`lsblk`）
- 查看磁盘分区信息（`fdisk -l /dev/vda`）
- 格式化持久化磁盘为ext4文件系统
- 创建挂载点目录（`/mnt/persistent`）
- 挂载持久化磁盘
- 创建测试文件并写入时间戳
- 同步文件系统

**与setup_persistence_final.exp的区别**：
- ✅ 执行`fdisk -l /dev/vda`检查（更详细）
- ⚠️ 更复杂，但功能相同
- ✅ 推荐使用setup_persistence_final.exp（更简洁）

## 常见问题和解决方案（持久性测试相关）

### 15. SSH连接超时（持久性测试）

**问题描述**：
expect脚本连接SSH时出现超时错误，无法建立连接。

**可能原因**：
- QEMU虚拟机未完全启动，SSH服务未就绪
- 端口配置错误
- 超时时间设置过短

**解决方案**：

1. **增加超时时间**：
   ```expect
   set timeout 120  # 从60秒增加到120秒
   ```

2. **确保虚拟机已启动**：
   ```bash
   # 检查QEMU进程
   ps aux | grep qemu-system-aarch64
   
   # 检查端口监听
   netstat -tlnp | grep 2222
   ```

3. **使用端口检查脚本**：
   ```bash
   # 启动脚本会自动检查端口
   ./start_openeuler.sh user --persistent
   ```

4. **添加重试机制**：
   ```expect
   set retry_count 0
   while {$retry_count < 3} {
       spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost
       expect {
           "#" {
               break
           }
           timeout {
               incr retry_count
               if {$retry_count >= 3} {
                   puts "ERROR: SSH connection timeout after 3 attempts"
                   exit 1
               }
               puts "Retry $retry_count/3..."
               sleep 5
           }
       }
   }
   ```

### 16. "No such file or directory" 错误（持久性测试）

**问题描述**：
挂载持久化磁盘时出现路径错误：
```
mount: mounting /dev/vda on /mnt/data failed: No such file or directory
```

**可能原因**：
- 挂载点目录不存在
- 脚本中使用了错误的路径（如`/mnt/data`而非`/mnt/persistent`）

**解决方案**：

1. **创建挂载点目录**：
   ```bash
   mkdir -p /mnt/persistent
   ```

2. **在脚本中添加目录创建**：
   ```expect
   send "mkdir -p /mnt/persistent\r"
   expect "#"
   
   send "mount /dev/vda /mnt/persistent\r"
   expect "#"
   ```

3. **检查路径一致性**：
   - 确保所有脚本使用相同的挂载点路径
   - 推荐使用 `/mnt/persistent` 作为标准路径

### 17. 密码过期场景处理（持久性测试）

**问题描述**：
首次登录时系统要求修改密码，expect脚本需要处理多种密码提示。

**解决方案**：

1. **使用setup_persistence_v2.exp**（完整处理）：
   ```expect
   # 处理5种密码提示
   expect {
       "Current password:" {
           send "${old_pass}\r"
           exp_continue
       }
       "New password:" {
           send "${new_pass}\r"
           exp_continue
       }
       "Retype new password:" {
           send "${new_pass}\r"
           exp_continue
       }
       "(root@localhost) Password:" {
           send "${new_pass}\r"
           exp_continue
       }
       "password:" {
           send "${new_pass}\r"
           exp_continue
       }
       "#" {}
   }
   ```

2. **使用setup_persistence_final.exp**（简化处理）：
   ```expect
   # 处理2种主要密码提示
   expect {
       "New password:" {
           send "openEuler12#\$\\r"
           expect "Retype new password:"
           send "openEuler12#\$\\r"
       }
       "password:" {
           send "openEuler12#\$\\r"
       }
   }
   ```

3. **使用ssh_guest_check.sh**（自动处理）：
   ```bash
   ./ssh_guest_check.sh  # 自动处理密码交互
   ```

### 18. 持久性验证流程

**问题描述**：
需要验证虚拟机重启后数据是否保留。

**解决方案**：

1. **完整的验证流程**：
   ```bash
   # 步骤1: 启动虚拟机并设置持久化
   ./start_openeuler.sh user --persistent
   ./setup_persistence_final.exp
   
   # 步骤2: 停止虚拟机
   ./stop_openeuler.sh default
   
   # 步骤3: 重新启动虚拟机
   ./start_openeuler.sh user --persistent
   
   # 步骤4: 验证数据是否保留
   ./verify_persistence.exp
   ```

2. **验证成功标志**：
   ```
   # 第一次运行写入的数据
   Persistence Test - First Run -  Thu Jan 1 00:00:32 UTC 1970
   
   # 第二次运行追加的数据
   Persistence Test - Second Run -  Thu Jan 1 00:00:20 UTC 1970
   ```

3. **检查持久化磁盘**：
   ```bash
   # 查看磁盘信息
   ./check_qemu.exp
   
   # 查看磁盘使用情况
   ssh -p 2222 root@localhost "df -h | grep vda"
   ```

### 19. 脚本重复和文件管理

**问题描述**：
存在多个功能相似的脚本，难以维护和使用。

**解决方案**：

1. **删除重复脚本**：
   - ❌ `setup_and_test_persistence.exp` - 与setup_persistence_v2.exp重复
   - ❌ `setup_persistence_v3.exp` - 与setup_persistence_v2.exp重复
   - ❌ `test_persistence.exp` - 路径错误，已标记为弃用

2. **保留推荐脚本**：
   - ✅ `setup_persistence_final.exp` - 持久化设置（推荐）
   - ✅ `verify_persistence.exp` - 持久性验证（推荐）
   - ✅ `check_qemu.exp` - QEMU状态检查
   - ✅ `setup_persistence_v2.exp` - 持久化设置（密码过期处理）

3. **配置.gitignore**：
   ```
   # QEMU runtime files
   *_disk.img
   *_qemu.log
   *_qemu.pid
   ```

### 20. expect脚本调试技巧

**问题描述**：
expect脚本运行时难以定位问题。

**解决方案**：

1. **启用详细输出**：
   ```expect
   exp_internal 1  # 显示expect内部匹配过程
   log_user 1      # 显示所有交互内容
   ```

2. **添加调试信息**：
   ```expect
   puts "DEBUG: Connecting to SSH..."
   spawn ssh -o StrictHostKeyChecking=no -p 2222 root@localhost
   puts "DEBUG: Spawned process with PID: $spawn_id"
   ```

3. **使用超时和错误处理**：
   ```expect
   expect {
       "#" {
           puts "SUCCESS: Connected successfully"
       }
       timeout {
           puts "ERROR: Connection timeout"
           exit 1
       }
       eof {
           puts "ERROR: Connection closed"
           exit 1
       }
   }
   ```

4. **测试单个expect块**：
   ```bash
   # 测试SSH连接
   expect -c '
   set timeout 30
   spawn ssh -o StrictHostKeyChecking=no -p 2222 root@localhost
   expect "password:"
   send "openEuler12#$\r"
   expect "#"
   send "exit\r"
   '
   ```

## 故障排查清单

当遇到问题时，按照以下顺序检查：

1. **虚拟机状态**：
   ```bash
   ps aux | grep qemu-system-aarch64
   cat default_qemu.pid
   ```

2. **端口监听**：
   ```bash
   netstat -tlnp | grep -E '2222|4444|8080'
   ```

3. **SSH连接**：
   ```bash
   ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost
   ```

4. **持久化磁盘**：
   ```bash
   ls -lh default_disk.img
   qemu-img info default_disk.img
   ```

5. **日志文件**：
   ```bash
   tail -f default_qemu.log
   ```

6. **expect脚本测试**：
   ```bash
   ./check_qemu.exp
   ```

## 获取帮助

如果以上解决方案无法解决您的问题，请：

1. 查看QEMU日志文件获取详细错误信息
2. 使用 `--verbose` 参数重新启动并查看详细输出
3. 检查系统日志：`dmesg | grep -i qemu`
4. 参考QEMU官方文档：https://www.qemu.org/docs/master/
