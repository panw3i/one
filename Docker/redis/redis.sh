#!/bin/bash
set -e

if [ "$1" = 'redis-server' ]; then

  if [ -z "$(grep "redhat.xyz" /usr/local/redis/redis.conf)" ]; then
	echo "Initialize redis"
	sed -i '1 i #redhat.xyz' /usr/local/redis/redis.conf

	#bind
	sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /usr/local/redis/redis.conf

	#persistence
	if [ $LOCAL_STROGE ]; then
		sed -i 's@dir \./@dir /usr/local/redis/data@' /usr/local/redis/redis.conf
		sed -i 's@appendonly no@appendonly yes@' /usr/local/redis/redis.conf
	fi

	#user auth
	if [ $REDIS_PASS ]; then
		echo "requirepass $REDIS_PASS" >>/usr/local/redis/redis.conf
		echo "Redis password: $REDIS_PASS" |tee /usr/local/redis/data/info
		AUTH="-a $REDIS_PASS"
	fi

	#redis master
	if [ $REDIS_MASTER ]; then
		[ -z "$MASTER_PORT" ] && MASTER_PORT=6379
		echo "slaveof $REDIS_MASTER $MASTER_PORT" >>/usr/local/redis/redis.conf
	fi

	#master pass
	if [ $MASTER_PASS ]; then
		echo "masterauth $MASTER_PASS" >>/usr/local/redis/redis.conf
	fi

	#VIP
	if [ $VIP ]; then
		cat >/vip.sh<<-END
		#!/bin/bash
		PASS="$AUTH"

		for i in {1..29}; do
		if [ "\$(echo info |redis-cli \$PASS |grep "role:" |awk -F: '{print \$2}')" == "master" ]; then
		    if [ -z "\$(ifconfig |grep $VIP)" ]; then
		        ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up || echo
		    fi
		    sleep 2
		else
		    if [ -n "\$(ifconfig |grep $VIP)" ]; then
		        ifconfig lo:0 del $VIP || echo
		    fi
		    sleep 2
		fi
		done
		END
		chmod +x /vip.sh
		echo "* * * * * . /etc/profile;/bin/sh /vip.sh &>/dev/null" >>/var/spool/cron/root
	fi

	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp -m multiport --dport 6379 -j DROP
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 6379 -m comment --comment MONGDB -j ACCEPT
		END
	fi
	
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep MONGDB`" ] && . /iptables.sh || echo

	echo "vm.overcommit_memory = 1" >>/etc/sysctl.conf
  fi

	echo "Start Redis ****"
	crond
	sysctl vm.overcommit_memory=1
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo 511 > /proc/sys/net/core/somaxconn
	exec "$@" 1>/dev/null

else
	echo -e "
	Example
					docker run -d --restart always --privileged \\
					-v /docker/redis:/usr/local/redis/data \\
					-p 6379:6379 \\
					-e REDIS_PASS=<bigpass> \\
					-e LOCAL_STROGE=<Y> \\
					-e REDIS_MASTER=<redhat.xyz> \\
					-e MASTER_PASS=<bigpass> \\
					-e VIP=<10.0.0.90> \\
					-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\
					--hostname redis \\
					--name redis redis
	"
fi
