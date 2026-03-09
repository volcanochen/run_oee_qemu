#!/bin/bash
# SSH Guest OS 检查脚本 - 使用循环处理密码交互

SSH_PORT=${1:-2222}
TIMEOUT=${2:-60}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 密码配置
OLD_PASSWORD="openEuler12#\$"
NEW_PASSWORD="newPass123\x21"

# 密码交互 expect 逻辑函数 - 可供其他脚本复用
# 参数: $1 = SSH端口, $2 = 超时时间, $3 = 旧密码, $4 = 新密码, $5 = 命令列表(可选)
# 返回: 0 = 成功, 1 = 失败
# 说明: 该函数处理SSH密码过期场景，自动完成旧密码->新密码->确认新密码的完整流程
# 如果提供了命令列表，会在登录后执行这些命令，不退出SSH会话
ssh_password_expect() {
    local port=${1:-2222}
    local timeout=${2:-60}
    local old_pass=${3:-"openEuler12#\$"}
    local new_pass=${4:-"newPass123\x21"}
    local commands=${5:-""}

    if [ -n "$commands" ]; then
        expect -c "
set timeout $timeout

spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $port root@localhost

expect {
    \"Current password:\" {
        send \"${old_pass}\\r\"
        exp_continue
    }
    \"New password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"Retype new password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"(root@localhost) Password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"#\" {}
    timeout {
        puts \"ERROR: SSH connection timeout\"
        exit 1
    }
}

send \"${commands}\\r\"
expect \"#\"

send \"exit\\r\"
expect eof
"
    else
        expect -c "
set timeout $timeout

spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $port root@localhost

expect {
    \"Current password:\" {
        send \"${old_pass}\\r\"
        exp_continue
    }
    \"New password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"Retype new password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"(root@localhost) Password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"password:\" {
        send \"${new_pass}\\r\"
        exp_continue
    }
    \"#\" {
        send \"exit\\r\"
        expect eof
    }
    timeout {
        puts \"ERROR: SSH connection timeout\"
        exit 1
    }
    eof {
        puts \"SSH session closed\"
        exit 0
    }
}
"
    fi
}

# 密码交互函数 - 使用循环处理密码登录
ssh_password_interactive() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${YELLOW}尝试 $attempt/$max_attempts: 连接 SSH...${NC}"
        
        ssh_password_expect "$SSH_PORT" "$TIMEOUT" "$OLD_PASSWORD" "$NEW_PASSWORD"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 密码交互成功${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}密码交互失败，等待 2 秒后重试...${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ 密码交互失败（超过最大重试次数）${NC}"
    return 1
}

# 网络检查命令执行函数 - 复用密码交互逻辑
execute_network_checks() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${YELLOW}尝试 $attempt/$max_attempts: 连接 SSH...${NC}"
        
        ssh_password_expect "$SSH_PORT" "$TIMEOUT" "$OLD_PASSWORD" "$NEW_PASSWORD" \
            "echo SSH_OK; uname -a; ping -c 3 20.205.243.166 2>&1 | head -10; curl -I https://github.com 2>&1 | head -10; curl -I http://www.baidu.com 2>&1 | head -10; nslookup github.com 2>&1 | head -10; cat /etc/resolv.conf; ip route show; netstat -tlnp; curl -v https://github.com 2>&1 | head -30"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 网络检查成功${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}网络检查失败，等待 2 秒后重试...${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ 网络检查失败（超过最大重试次数）${NC}"
    return 1
}

# 主程序
main() {
    echo "=== openEuler Guest OS 网络检查 ==="
    echo "SSH 端口: $SSH_PORT"
    echo ""
    
    # 先处理密码交互（修改密码）
    echo "=== 处理密码交互 ==="
    ssh_password_interactive
    
    # 执行网络检查
    echo ""
    echo "=== 执行网络检查 ==="
    execute_network_checks
}

main
