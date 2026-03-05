#!/usr/bin/expect -f

set timeout 60
set ssh_password "openEuler12#$"

spawn ssh -o StrictHostKeyChecking=no -p 2222 root@localhost
puts "DEBUG: Spawned SSH process"

expect {
    "*password:*" {
        puts "DEBUG: Got password prompt"
        send "$ssh_password\r"
        exp_continue
    }
    "*#*" {
        puts "DEBUG: Got shell prompt (#)"
        send "hostname\r"
        expect "*#*"
        puts "DEBUG: Ran hostname command"
        send "whoami\r"
        expect "*#*"
        puts "DEBUG: Ran whoami command"
        send "ip addr show\r"
        expect "*#*"
        puts "DEBUG: Ran ip addr command"
        send "ping -c 3 8.8.8.8\r"
        expect "*#*"
        puts "DEBUG: Ran ping command"
        send "exit\r"
        expect eof
    }
    "*$*" {
        puts "DEBUG: Got shell prompt ($)"
        send "hostname\r"
        expect "*$*"
        puts "DEBUG: Ran hostname command"
        send "whoami\r"
        expect "*$*"
        puts "DEBUG: Ran whoami command"
        send "ip addr show\r"
        expect "*$*"
        puts "DEBUG: Ran ip addr command"
        send "ping -c 3 8.8.8.8\r"
        expect "*$*"
        puts "DEBUG: Ran ping command"
        send "exit\r"
        expect eof
    }
    "*%*" {
        puts "DEBUG: Got shell prompt (%)"
        send "hostname\r"
        expect "*%*"
        puts "DEBUG: Ran hostname command"
        send "whoami\r"
        expect "*%*"
        puts "DEBUG: Ran whoami command"
        send "ip addr show\r"
        expect "*%*"
        puts "DEBUG: Ran ip addr command"
        send "ping -c 3 8.8.8.8\r"
        expect "*%*"
        puts "DEBUG: Ran ping command"
        send "exit\r"
        expect eof
    }
    timeout {
        puts "DEBUG: Connection timeout"
        exit 1
    }
    eof {
        puts "DEBUG: Connection closed"
        exit 0
    }
}
