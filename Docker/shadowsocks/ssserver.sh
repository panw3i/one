#!/bin/bash
set -e

if [ "$1" = 'shadowsocks' ]; then

: ${SS_PASS:="$(openssl passwd $RANDOM)"}
: ${SS_EMOD:="aes-256-cfb"}
: ${SS_PORT:="8443"}
: ${SS_OBFS:="tls1.2_ticket_auth_compatible"}
: ${SS_PROTOCOL:="auth_aes128_sha1"}
: ${SL_ADDR:="127.0.0.1"}
: ${SL_PORT:="1080"}

if [ ! -f /usr/bin/shadowsocks ]; then 
	if [ $SS_ADDR ]; then
		if [ $SSR ]; then
			echo -e "shadowsocks type: SSR \nlocal port: $SL_PORT"
			echo "/shadowsocksr/shadowsocks/local.py -s $SS_ADDR -p $SS_PORT -k $SS_PASS -m $SS_EMOD -O $SS_PROTOCOL -o $SS_OBFS -b $SL_ADDR -l $SL_PORT" >/usr/bin/shadowsocks
		else
			echo -e "shadowsocks type: SS \nlocal port: $SL_PORT"
			echo "/shadowsocks/shadowsocks/local.py -s $SS_ADDR -p $SS_PORT -k $SS_PASS -m $SS_EMOD -b $SL_ADDR -l $SL_PORT" >/usr/bin/shadowsocks
		fi
	else
		if [ $SSR ]; then
			echo -e "shadowsocks type: SSR \npassword: $SS_PASS \nencryption mode: $SS_EMOD \nservice port: $SS_PORT \nprotocol: $SS_PROTOCOL \nobfs: $SS_OBFS"
			echo "/shadowsocksr/shadowsocks/server.py -p $SS_PORT -k $SS_PASS -m $SS_EMOD -O $SS_PROTOCOL -o $SS_OBFS" >/usr/bin/shadowsocks
		else
			echo -e "shadowsocks type: SS \npassword: $SS_PASS \nencryption mode: $SS_EMOD \nservice port: $SS_PORT"
			echo "/shadowsocks/shadowsocks/server.py -p $SS_PORT -k $SS_PASS -m $SS_EMOD" >/usr/bin/shadowsocks
		fi
	fi
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
				-e SS_OBFS=[tls1.2_ticket_auth_compatible] \\
				-e SS_PROTOCOL=[auth_aes128_sha1] \\
				-e SSR=<Y> \\
				-e SS_ADDR=<SS_ADDR> \\
				-e SL_ADDR=[127.0.0.1] \\
				-e SL_PORT=[1080] \\
				--hostname shadowsocks --name shadowsocks shadowsocks
	"
fi
