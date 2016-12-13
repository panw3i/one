#!/bin/bash
set -e

if [ "$1" = 'redis-server' ]; then

: ${PASSWORD:=$(pwmake 64)}

if [ -z "$(grep "redhat.xyz" /usr/local/redis/redis.conf)" ]; then
	echo "Initialize redis"
	sed -i '1 i #redhat.xyz' /usr/local/redis/redis.conf
	
	#bind
	sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /usr/local/redis/redis.conf
	
	#persistence
	if [ $LOCAL_STROGE ]
		sed -i 's@dir \./@dir /usr/local/redis/data@' /usr/local/redis/redis.conf
		sed -i 's@appendonly no@appendonly yes@' /usr/local/redis/redis.conf
	fi

	#Client Authentication
	if [ "$REDIS_PASS" ]; then
		if [ "$REDIS_PASS" == "Y" ]; then
			sed -i 's/# requirepass foobared/requirepass '$PASSWORD'/' /usr/local/redis/redis.conf
			echo "Redis password: $PASSWORD"
		else
			sed -i 's/# requirepass foobared/requirepass '$REDIS_PASS'/' /usr/local/redis/redis.conf
			echo "Redis password: $REDIS_PASS"
		fi
	fi

	#port
	if [ $REDIS_PORT ]; then
		sed -i 's/port 6379/port '$REDIS_PORT'/' /usr/local/redis/redis.conf
	fi

	echo "vm.overcommit_memory = 1" >>/etc/sysctl.conf
fi

	echo "Start ****"
    sysctl vm.overcommit_memory=1
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo 511 > /proc/sys/net/core/somaxconn
	exec "$@"

else
	echo -e "
	Example
					docker run -d --restart always --privileged \\
					-v /docker/redis:/usr/local/redis/data \\
					-p 16379:6379 \\
					-e REDIS_PASS=<bigpass> \\
					-e REDIS_PORT=[6379] \\
					-e LOCAL_STROGE=Y \\
					--hostname redis \\
					--name redis redis
	"
fi