#!/bin/bash
set -e

: ${USER:=root}
: ${PASS:=$(pwmake 64)}

__setup(){
    mkdir -p /var/run/sshd
	echo "$USER:$PASS" | chpasswd
	ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
	sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	\cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

__print(){
	echo -e "ssh username password: $USER\t $PASS"
}

if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	__setup
	__print
fi

ntpd -u ntp:ntp -g

exec "$@"
