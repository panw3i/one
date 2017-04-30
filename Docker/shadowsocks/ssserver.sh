#!/bin/bash
set -e

if [ "$1" = 'shadowsocks' ]; then

: ${SS_PASS:=$(pwmake 64)}
: ${SS_EMOD:=aes-256-cfb}
: ${SS_PORT:=8443}

if [ ! -f /usr/bin/shadowsocks ]; then 
	echo -e "password: $SS_PASS \nencryption mode: $SS_EMOD" 
	echo "/usr/bin/ssserver -p $SS_PORT -k $SS_PASS -m $SS_EMOD" >/usr/bin/shadowsocks 
	chmod +x /usr/bin/shadowsocks 
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d --restart always \\
				-p 8443:8443 \
				-e SS_PASS=[pwmake 64] \\
				-e SS_EMOD=[aes-256-cfb] \\
				-e SS_PORT=[8443] \\
				--hostname shadowsocks --name shadowsocks shadowsocks
	"
fi
