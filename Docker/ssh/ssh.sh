#!/bin/bash
set -e

: ${USER:=root}
: ${PASS:=$(pwmake 64)}

__setup(){
    mkdir -p /var/run/sshd
	echo "$SSH_USERNAME:$SSH_USERPASS" | chpasswd
	ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

__print(){
	echo -e "ssh username password: $SSH_USERNAME\t $SSH_USERPASS"
}

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	__setup
	__print
fi

ntpd -u ntp:ntp -g

exec "$@"
