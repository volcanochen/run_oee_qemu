#!/bin/bash
# 网络检查脚本 - 验证 Guest OS 网络连接状态

SSH_PORT=${1:-2222}
TIMEOUT=${2:-60}
MAX_RETRIES=${3:-10}
RETRY_INTERVAL=${4:-5}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_ssh_connection() {
    echo -e "${YELLOW}检查 SSH 连接...${NC}"
    local attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "尝试 $attempt/$MAX_RETRIES..."
        if timeout $TIMEOUT expect -c "
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
                    exit 1
                }
            }
            send \"echo SSH_OK\\r\"
            expect \"SSH_OK\"
            send \"exit\\r\"
            expect eof
        " 2>/dev/null; then
            echo -e "${GREEN}✓ SSH 连接成功${NC}"
            return 0
        fi
        echo -e "${YELLOW}SSH 连接失败，等待 $RETRY_INTERVAL 秒后重试...${NC}"
        sleep $RETRY_INTERVAL
        attempt=$((attempt + 1))
    done
    echo -e "${RED}✗ SSH 连接失败（超过最大重试次数）${NC}"
    return 1
}

check_dns_resolution() {
    echo -e "${YELLOW}检查 DNS 解析...${NC}"
    if timeout $TIMEOUT expect -c "
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
                exit 1
            }
        }
        send \"nslookup www.baidu.com 2>&1 | head -10\\r\"
        expect \"#\"
        send \"exit\\r\"
        expect eof
    " 2>/dev/null | grep -q "Address:"; then
        echo -e "${GREEN}✓ DNS 解析成功${NC}"
        return 0
    else
        echo -e "${RED}✗ DNS 解析失败${NC}"
        return 1
    fi
}

check_http_access() {
    echo -e "${YELLOW}检查 HTTP 访问...${NC}"
    if timeout $TIMEOUT expect -c "
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
                exit 1
            }
        }
        send \"curl -I http://www.baidu.com 2>&1 | head -1\\r\"
        expect \"#\"
        send \"exit\\r\"
        expect eof
    " 2>/dev/null | grep -q "200 OK"; then
        echo -e "${GREEN}✓ HTTP 访问成功${NC}"
        return 0
    else
        echo -e "${RED}✗ HTTP 访问失败${NC}"
        return 1
    fi
}

check_network_routes() {
    echo -e "${YELLOW}检查网络路由...${NC}"
    if timeout $TIMEOUT expect -c "
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
                exit 1
            }
        }
        send \"ip route show\\r\"
        expect \"#\"
        send \"cat /etc/resolv.conf\\r\"
        expect \"#\"
        send \"exit\\r\"
        expect eof
    " 2>/dev/null; then
        echo -e "${GREEN}✓ 网络路由信息获取成功${NC}"
        return 0
    else
        echo -e "${RED}✗ 网络路由信息获取失败${NC}"
        return 1
    fi
}

print_network_summary() {
    echo ""
    echo -e "${GREEN}=== 网络检查完成 ===${NC}"
    echo "所有网络检查已执行完成。"
    echo ""
    echo "如果某些检查失败，请检查："
    echo "  1. QEMU 虚拟机是否正常运行"
    echo "  2. 网络端口是否正确转发"
    echo "  3. DNS 配置是否正确"
    echo ""
}

# 主程序
main() {
    echo "=== openEuler 网络检查工具 ==="
    echo "SSH 端口: $SSH_PORT"
    echo "超时时间: ${TIMEOUT}s"
    echo "重试次数: $MAX_RETRIES"
    echo ""
    
    local failed=0
    
    check_ssh_connection || failed=$((failed + 1))
    check_dns_resolution || failed=$((failed + 1))
    check_http_access || failed=$((failed + 1))
    check_network_routes || failed=$((failed + 1))
    
    print_network_summary
    
    if [ $failed -gt 0 ]; then
        echo -e "${RED}网络检查完成，有 $failed 项检查失败${NC}"
        return 1
    else
        echo -e "${GREEN}网络检查完成，所有检查通过${NC}"
        return 0
    fi
}

main
