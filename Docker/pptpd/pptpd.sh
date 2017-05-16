#!/bin/bash
set -e

if [ "$1" = 'pptpd' ]; then

: ${IP_RANGE:=10.9.0}
: ${VPN_USER:=jiobxn}
: ${VPN_PASS:=$(pwmake 64)}

if [ -z "$(grep "8.8.8.8" /etc/ppp/options.pptpd)" ]; then
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(curl -s https://httpbin.org/ip |awk -F\" 'NR==2{print $4}')
	fi

	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(curl -s https://showip.net/)
	fi

	if [ -z $SERVER_IP ]; then
		SERVER_IP=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi

	# Configure pptpd
	sed -i "/# or/i localip $IP_RANGE.1\nremoteip $IP_RANGE.5-254" /etc/pptpd.conf
	sed -i "s/#connections 100/connections 253/g" /etc/pptpd.conf

	sed -i 's/#ms-dns 10.0.0.1/ms-dns 8.8.8.8\nms-dns 8.8.4.4/g' /etc/ppp/options.pptpd

	echo "$VPN_USER       pptpd      $VPN_PASS          *" >> /etc/ppp/chap-secrets
	
	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	sysctl -p

	# iptables
	cat > /iptables.sh <<-END
	iptables -t nat -I POSTROUTING -s $IP_RANGE.0/24 -o $DEV -j MASQUERADE
	iptables -I FORWARD -s $IP_RANGE.0/24 -j ACCEPT
	iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -I INPUT -p 47 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 1723 -m comment --comment PPTPD -j ACCEPT
	iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	END

	echo -e "
	VPN USER: $VPN_USER
	VPN PASS: $VPN_PASS
	SERVER: $SERVER_IP" |tee /key/pptpd.log
fi

	echo
	echo "Start ****"
	[ -z "`iptables -S |grep PPTPD`" ] && . /iptables.sh
	exec "$@"

else

	echo -e "
	Example
			docker run -d --restart always --privileged \\
			-v /docker/pptpd:/key \\
			--network=host \\
			-e VPN_USER=[jiobxn] \\
			-e VPN_PASS=<123456> \\
			-e IP_RANGE:=[10.9.0] \\
			--hostname=pptpd --name=pptpd pptpd"

fi
