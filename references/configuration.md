# openEuler QEMU虚拟机配置说明

## 系统配置

### 硬件配置
- 机器类型: virt (通用ARM64平台)
- CPU: cortex-a53
- SMP: 2个CPU核心
- 内存: 1024MB

### 启动参数
```
-machine virt,gic-version=3
-cpu cortex-a53
-smp 2
-m 1024
```

### 内核参数
```
console=ttyAMA0,115200
earlycon=pl011,0x9000000
root=/dev/ram0
rw
ip=dhcp
modules-load=virtio_pci
```

## 网络配置

### 用户模式网络
- 网络栈: QEMU内置用户模式网络
- IP地址: 10.0.2.15/24
- 网关: 10.0.2.2
- DNS: 10.0.2.3
- 权限: 无需root

### TAP接口网络
- 网桥: br0 (192.168.100.1/24)
- 接口: tap0
- 权限: 需要root
- 网络: 直接连接主机网络

## 存储配置

### 持久存储
- 格式: qcow2
- 大小: 2GB (最小)
- 设备: /dev/vda (virtio)
- 缓存: none
- I/O: native

### 根文件系统
- 类型: initramfs (cpio.gz)
- 路径: /home/volcano/myws/oee2403/build/qemu-aarch64/tmp/deploy/images/qemu-aarch64/openeuler-image-qemu-aarch64.cpio.gz

## 访问方式

### 串口控制台
- 设备: ttyAMA0
- 波特率: 115200
- 模式: nographic

### QEMU Monitor
- 协议: telnet
- 地址: 127.0.0.1:4444
- 命令: info registers, info cpus, savevm, loadvm, quit

### 网络访问
- SSH: localhost:2222 → 10.0.2.15:22
- HTTP: localhost:8080 → 10.0.2.15:80

## 登录信息

- 用户名: root
- 密码: openEuler12#$
- 登录方式: 串口或SSH

## 常用命令

### QEMU Monitor命令
```
info status      # 查看虚拟机状态
info registers   # 查看寄存器
info cpus        # 查看CPU信息
info snapshots   # 查看快照
savevm <name>    # 保存快照
loadvm <name>    # 恢复快照
cont             # 继续运行
quit             # 退出Monitor
```

### 虚拟机内命令
```bash
# 查看磁盘
lsblk
fdisk -l /dev/vda

# 查看网络
ip addr show
ip route
cat /etc/resolv.conf

# 关机
sudo shutdown -h now
```

## 注意事项

1. 首次启动需要创建持久存储磁盘镜像
2. TAP模式需要root权限
3. 确保2222和8080端口未被占用
4. QEMU Monitor通过telnet访问，按Ctrl+]退出
5. 数据持久化需要手动分区和挂载/dev/vda
