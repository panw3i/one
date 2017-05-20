#!/bin/bash
set -e

: ${ZK_MEM:="$(($(free -m |grep Mem |awk '{print $2}')*70/100))m"}

if [ "$1" = 'bin/zkServer.sh' ]; then
  if [ ! -d /var/lib/zookeeper/version-2 ]; then
	cp /usr/local/zookeeper/conf/zoo_sample.cfg /usr/local/zookeeper/conf/zoo.cfg
	sed -i 's#/tmp/zookeeper#/var/lib/zookeeper#' /usr/local/zookeeper/conf/zoo.cfg
	sed -i 's/#maxClientCnxns=60/maxClientCnxns=0/' /usr/local/zookeeper/conf/zoo.cfg
	sed -i 's/syncLimit=5/syncLimit=2/' /usr/local/zookeeper/conf/zoo.cfg
	echo "export JVMFLAGS=\"-Xms$ZK_MEM -Xmx$ZK_MEM \$JVMFLAGS\"" >/usr/local/zookeeper/conf/java.env 

	#Clustered
	if [ $ZK_SERVER ]; then
		n=0
		for i in $(echo $ZK_SERVER |sed 's/,/\n/g'); do
			[ $(echo $ZK_SERVER |sed 's/,/\n/g' |wc -l) -lt 3 ] && echo "nodes is greater than or equal to 3" && exit 1
			n=$[$n+1]
			echo "server.$n=$i:2888:3888" >>/usr/local/zookeeper/conf/zoo.cfg
			[ -n "$(ifconfig |grep $i)" ] && echo $n >/var/lib/zookeeper/myid
		done
		echo "echo stat | nc 127.0.0.1 2181 |awk '\$1==\"Mode:\"{print \$2}'" >/usr/local/bin/zoo
		chmod +x /usr/local/bin/zoo
	fi
	
	#IPTABLES
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp -m multiport --dport 2181 -j DROP
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 2181 -m comment --comment ZOOKEEPER -j ACCEPT
		iptables -I INPUT -s -p tcp -m state --state NEW -m tcp --dport 2888 -m comment --comment ZOOKEEPER -j ACCEPT
		iptables -I INPUT -s -p tcp -m state --state NEW -m tcp --dport 3888 -m comment --comment ZOOKEEPER -j ACCEPT
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		END
	fi

	#VIP
	if [ $VIP ]; then
		cat >/vip.sh<<-END
		#!/bin/bash
		for i in {1..29}; do
		if [ -n "\$(netstat -tpnl |grep ":2888 ")" ]; then
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
  fi

	echo "Start GFW ****"
	crond
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep ZOOKEEPER`" ] && . /iptables.sh || echo
	exec "$@" 1>/dev/null

else

    echo -e "
    Example:
				docker run -d --restart always [--privileged] \\
				-v /docker/zookeeper:/var/lib/zookeeper \\
				-p 2181:2181 \\
				-e ZK_MEM=[2048m] \\
				-e ZK_SERVER=<"10.0.0.71,10.0.0.72,10.0.0.73"> \\
				-e VIP=<10.0.0.70> \\
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\
				--hostname zookeeper \\
				--name zookeeper zookeeper
	"
fi
