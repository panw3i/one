#!/bin/bash
set -e

: ${GFW_PORT:="10001..10005"}
: ${GFW_PASS:="$(pwmake 64)"}
: ${GFW_EMOD:="squid"}
: ${SQUID_PASS:="$(pwmake 64)"}

if [ "$1" = 'gfw.press' ]; then
  if [ ! -f /iptables.sh ]; then
	#squid
	sed -i 's/http_port 3128/http_port 127.0.0.1:3128/' /etc/squid/squid.conf
	if [ -z "$(grep "redhat.xyz" /etc/squid/squid.conf)" ]; then
		cat >>/etc/squid/squid.conf<<-END
		#redhat.xyz
		shutdown_lifetime 3 seconds
		access_log none
		cache_log /dev/null
		logfile_rotate 0
		cache deny all
		END
	fi

	if [ $SQUID_USER ]; then
		cat >>/squid-auth.txt <<-END
		auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd 
		auth_param basic realm Squid proxy-caching web server 
		auth_param basic credentialsttl 2 hours 
		auth_param basic casesensitive off 
		acl authuser proxy_auth REQUIRED 
		http_access allow authuser
		END
	
		sed -i '/# Recommended minimum configuration:/ r /squid-auth.txt' /etc/squid/squid.conf
		echo "$SQUID_USER:$(openssl passwd -apr1 $SQUID_PASS)" > /etc/squid/passwd
		echo "Squid user AND password: $SQUID_USER  $SQUID_PASS" |tee /key/squid_info
	fi
	
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	
	#sockd
	if [ ! -f /etc/sockd.conf ]; then
		cat >/etc/sockd.conf<<-END 
		internal: 127.0.0.1 port = 3128
		external: $DEV
		clientmethod: none
		socksmethod: none
		user.notprivileged: nobody
		errorlog: /var/log/sockd.err
		#logoutput: /var/log/sockd.log
		client pass { from: 0/0  to: 0/0 }
		socks block { from: 0/0 to: lo }
		socks pass { from: 0/0 to: 0/0 }
		END
	fi
	
	#PASS
	\rm /gfw.press/user.tx_
	if [ "$GFW_PASS" == "N" ]; then
		echo "for i in {$GFW_PORT}; do echo \"\$i \$(pwmake 64)\" >> /gfw.press/user.tx_ ; done" >/gfw.press/make_user.sh
	else
		echo "for i in {$GFW_PORT}; do echo \"\$i $GFW_PASS\" >> /gfw.press/user.tx_ ; done" >/gfw.press/make_user.sh
	fi
	. /gfw.press/make_user.sh
	\cp  /gfw.press/user.tx_ /gfw.press/user.txt
	echo -e "\ngfw.press port and passwd: \n\n$(cat /gfw.press/user.txt)\n" |tee /key/gfw.log
	
	#IPTABLES
	cat > /iptables.sh <<-END
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $(echo $GFW_PORT |sed 's/\.\./:/') -m comment --comment GFW -j ACCEPT
	iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	END
  fi

	echo
	echo "Start GFW ****"
	if [ "$GFW_EMOD" == "sockd" ]; then
		/usr/local/sbin/sockd -D
	else
		/usr/sbin/squid -f /etc/squid/squid.conf
	fi
	
	[ -f /gfw.press/server.lock ] && \rm /gfw.press/server.lock
	[ -z "`iptables -S |grep $(awk 'NR==1{print $13}' /iptables.sh)`" ] && . /iptables.sh || echo
	MEM="$(($(free -m |grep Mem |awk '{print $2}')*50/100))m"
	java -Dfile.encoding=utf-8 -Dsun.jnu.encoding=utf-8 -Duser.timezone=Asia/Shanghai  -Xms$MEM -Xmx$MEM -classpath `find /gfw.press/lib/*.jar | xargs echo | sed 's/ /:/g'`:/gfw.press/bin press.gfw.Server

else

    echo -e "
    Example:
				docker run -d --restart always --privileged \\
				--network=host \\
				-v /docker/gfw.press:/key \\
				-p 8080:10005 \\
				-e GFW_PORT=["10001..10005"] \\
				-e GFW_PASS=[newpass|N] \\
				-e GFW_EMOD=[squid|sockd] \\
				-e SQUID_USER=<jiobxn> \\
				-e SQUID_PASS=<123456> \\
				--hostname gfw.press \\
				--name gfw.press gfw.press
	"
fi
