# openEuler QEMU虚拟机启动指南

## 快速开始

```bash
cd /home/volcano/myws/oee2403/qemu_oee
./start_openeuler.sh [user|tap]
```

## 目录结构

```
qemu_oee/
├── start_openeuler.sh   # 启动脚本
├── stop_openeuler.sh    # 停止脚本
├── qemu-ifup           # TAP网络配置脚本
├── openeuler_disk.img  # 持久存储磁盘镜像
└── qemu.log            # QEMU运行日志
```

## 使用说明

### 1. 启动虚拟机

**用户模式网络（默认）**：
```bash
cd /home/volcano/myws/oee2403/qemu_oee
./start_openeuler.sh
```

**TAP接口网络模式**：
```bash
./start_openeuler.sh tap
```

### 2. 访问虚拟机

**通过SSH**：
```bash
ssh -p 2222 root@localhost
# 密码: openEuler12#$
```

**通过QEMU Monitor**：
```bash
telnet localhost 4444
```

### 3. 停止虚拟机

```bash
./stop_openeuler.sh
```

### 4. 查看日志

```bash
tail -f /home/volcano/myws/oee2403/qemu_oee/qemu.log
```

## 网络配置

- **用户模式**: 无需root权限，自动端口转发
- **TAP模式**: 需要root权限，直接连接主机网络

## 端口映射

- Host 2222 → Guest 22 (SSH)
- Host 8080 → Guest 80 (HTTP)

## 故障排除

### 1. 找不到磁盘镜像

```bash
qemu-img create -f qcow2 /home/volcano/myws/oee2403/qemu_oee/openeuler_disk.img 2G
```

### 2. SSH主机密钥变更

```bash
ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:2222'
```

### 3. 端口被占用

检查2222和8080端口是否被占用：
```bash
netstat -tlnp | grep -E '2222|8080'
```
