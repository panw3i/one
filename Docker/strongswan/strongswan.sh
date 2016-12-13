#!/bin/bash
set -e

if [ "$1" = 'strongswan' ]; then

: ${IP_RANGE:=10.11.0}
: ${VPN_USER:=jiobxn}
: ${VPN_PASS:=$(pwmake 64)}
: ${VPN_PSK:=jiobxn.com}
: ${P12_PASS:=jiobxn.com}
: ${CLIENT_CN:="strongSwan VPN"}
: ${CA_CN:="strongSwan CA"}


	
if [ -z "$(grep "redhat.xyz" /etc/strongswan/ipsec.conf)" ]; then
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(curl -s https://httpbin.org/ip |awk -F\" 'NR==2{print $4}')
	fi

	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(curl -s https://showip.net/)
	fi

	if [ -z $SERVER_CN ]; then
		SERVER_CN=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi

	echo "Initialize strongswan"
	if [ "$(ls /key/ |egrep -c "server.crt|server.key|ca.crt|ca.key|client.crt|client.key|strongswan.p12")" -ne 7 ]; then
		#Create certificate
		cd /etc/strongswan/ipsec.d
		strongswan pki --gen --type rsa --size 4096 --outform pem > ca-key.pem
		chmod 600 ca-key.pem
		strongswan pki --self --ca --lifetime 3650 --in ca-key.pem --type rsa --dn "C=CH, O=strongSwan, CN=$CA_CN" --outform pem > ca-cert.pem

		strongswan pki --gen --type rsa --size 2048 --outform pem > server-key.pem
		chmod 600 server-key.pem
		strongswan pki --pub --in server-key.pem --type rsa | strongswan pki --issue --lifetime 3650 --cacert ca-cert.pem --cakey ca-key.pem --dn "C=CH, O=strongSwan, CN=$SERVER_CN" --san $SERVER_CN --flag serverAuth --flag ikeIntermediate --outform pem > server-cert.pem 

		strongswan pki --gen --type rsa --size 2048 --outform pem > client-key.pem
		chmod 600 client-key.pem
		strongswan pki --pub --in client-key.pem --type rsa | strongswan pki --issue --lifetime 3650 --cacert ca-cert.pem --cakey ca-key.pem --dn "C=CH, O=strongSwan, CN=$CLIENT_CN" --outform pem > client-cert.pem

		openssl pkcs12 -export -inkey client-key.pem -in client-cert.pem -name "IPSec's VPN Certificate" -certfile ca-cert.pem -caname "strongSwan CA" -out strongswan.p12 -password "pass:$P12_PASS"

		\cp ca-key.pem /etc/strongswan/ipsec.d/private/ca.key
		\cp ca-cert.pem /etc/strongswan/ipsec.d/cacerts/ca.crt
		\cp server-key.pem /etc/strongswan/ipsec.d/private/server.key
		\cp server-cert.pem /etc/strongswan/ipsec.d/certs/server.crt
		\cp client-key.pem /etc/strongswan/ipsec.d/private/client.key
		\cp client-cert.pem /etc/strongswan/ipsec.d/certs/client.crt
		\cp ca-key.pem /key/ca.key
		\cp ca-cert.pem /key/ca.crt
		\cp server-key.pem /key/server.key
		\cp server-cert.pem /key/server.crt
		\cp client-key.pem /key/client.key
		\cp client-cert.pem /key/client.crt
		\cp strongswan.p12 /key/strongswan.p12

	else
		\cp /key/ca.key /etc/strongswan/ipsec.d/private/ca.key
		\cp /key/ca.crt /etc/strongswan/ipsec.d/cacerts/ca.crt
		\cp /key/server.key /etc/strongswan/ipsec.d/private/server.key
		\cp /key/server.crt /etc/strongswan/ipsec.d/certs/server.crt
		\cp /key/client.key /etc/strongswan/ipsec.d/private/client.key
		\cp /key/client.crt /etc/strongswan/ipsec.d/certs/client.crt
		echo "Certificate already exists, skip"
	fi
	
	
	# IPSec configuration file
	cat >/etc/strongswan/ipsec.conf <<-END
	#redhat.xyz
	config setup
	    uniqueids=never 
	conn iOS_cert
	    keyexchange=ikev1
	    fragmentation=yes
	    left=%defaultroute
	    leftauth=pubkey
	    leftsubnet=0.0.0.0/0
	    leftcert=server.crt
	    right=%any
	    rightauth=pubkey
	    rightauth2=xauth
	    rightsourceip=$IP_RANGE.128/25
	    rightdns=8.8.8.8,8.8.4.4
	    rightcert=client.crt
	    auto=add
	conn android_xauth_psk
	    keyexchange=ikev1
	    left=%defaultroute
	    leftauth=psk
	    leftsubnet=0.0.0.0/0
	    right=%any
	    rightauth=psk
	    rightauth2=xauth
	    rightsourceip=$IP_RANGE.128/25
	    rightdns=8.8.8.8,8.8.4.4
	    auto=add
	conn networkmanager-strongswan
	    keyexchange=ikev2
	    left=%defaultroute
	    leftauth=pubkey
	    leftsubnet=0.0.0.0/0
	    leftcert=server.crt
	    right=%any
	    rightauth=pubkey
	    rightsourceip=$IP_RANGE.128/25
	    rightdns=8.8.8.8,8.8.4.4
	    rightcert=client.crt
	    auto=add
	conn ios_ikev2
	    keyexchange=ikev2
	    ike=aes256-sha256-modp2048,3des-sha1-modp2048,aes256-sha1-modp2048!
	    esp=aes256-sha256,3des-sha1,aes256-sha1!
	    rekey=no
	    left=%defaultroute
	    leftid=$SERVER_CN
	    leftsendcert=always
	    leftsubnet=0.0.0.0/0
	    leftcert=server.crt
	    right=%any
	    rightauth=eap-mschapv2
	    rightsourceip=$IP_RANGE.128/25
	    rightdns=8.8.8.8,8.8.4.4
	    rightsendcert=never
	    eap_identity=%any
	    dpdaction=clear
	    fragmentation=yes
	    auto=add
	conn windows7
	    keyexchange=ikev2
	    ike=aes256-sha1-modp1024!
	    rekey=no
	    left=%defaultroute
	    leftauth=pubkey
	    leftsubnet=0.0.0.0/0
	    leftcert=server.crt
	    right=%any
	    rightauth=eap-mschapv2
	    rightsourceip=$IP_RANGE.128/25
	    rightdns=8.8.8.8,8.8.4.4
	    rightsendcert=never
	    eap_identity=%any
	    auto=add
	conn L2TP-PSK
	    keyexchange=ikev1
	    authby=secret
	    leftprotoport=17/1701
	    leftfirewall=no
	    rightprotoport=17/%any
	    type=transport
	    auto=add
	END
	
	
	# strongSwan configuration file
	cat >/etc/strongswan/strongswan.conf <<-END
	charon {
		load_modular = yes
		duplicheck.enable = no
		compress = yes
		plugins {
			include strongswan.d/charon/*.conf
		}
		dns1 = 8.8.8.8
		dns2 = 8.8.4.4
		nbns1 = 8.8.8.8
		nbns2 = 8.8.4.4
	}
	include strongswan.d/*.conf
	END
	
	
	# IPSec auth file
	cat >/etc/strongswan/ipsec.secrets <<-END
	: RSA server.key
	: PSK "$VPN_PSK"
	$VPN_USER %any : EAP "$VPN_PASS"
	$VPN_USER %any : XAUTH "$VPN_PASS"
	END
	
	
	# L2TP auth file
	echo "$VPN_USER       l2tpd      $VPN_PASS          *" >> /etc/ppp/chap-secrets
	
	
	# L2TP configuration file
	cat >/etc/xl2tpd/xl2tpd.conf <<-END
	[global]
	listen-addr = 0.0.0.0
	auth file = /etc/ppp/chap-secrets
	port = 1701

	[lns default]
	ip range = $IP_RANGE.2-$IP_RANGE.126
	local ip = $IP_RANGE.1
	require chap = yes
	refuse pap = yes
	require authentication = yes
	name = LinuxVPNserver
	ppp debug = yes
	pppoptfile = /etc/ppp/options.xl2tpd
	length bit = yes
	END
	

	# L2TP configuration file
	cat >/etc/ppp/options.xl2tpd <<-END
	ipcp-accept-local
	ipcp-accept-remote
	require-mschap-v2
	ms-dns 8.8.8.8
	ms-dns 8.8.4.4
	asyncmap 0
	noccp
	auth
	crtscts
	idle 1800
	mtu 1410
	mru 1410
	nodefaultroute
	debug
	lock
	hide-password
	modem
	name l2tpd
	proxyarp
	lcp-echo-interval 30
	lcp-echo-failure 4
	connect-delay 5000
	END

	# iptables
	cat > /iptables.sh <<-END
	iptables -t nat -I POSTROUTING -s $IP_RANGE.0/24 -o $DEV -j MASQUERADE
	iptables -I FORWARD -s $IP_RANGE.0/24 -j ACCEPT
	iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -I INPUT -p udp -m state --state NEW -m udp --dport 500 -j ACCEPT
	iptables -I INPUT -p udp -m state --state NEW -m udp --dport 4500 -j ACCEPT
	iptables -I INPUT -p udp -m state --state NEW -m udp --dport 1701 -j ACCEPT
	iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	sysctl -w net.ipv4.ip_forward=1
	END

	echo -e "
	VPN USER: $VPN_USER
	VPN PASS: $VPN_PASS
	VPN PSK: $VPN_PSK
	P12 PASS: $P12_PASS
	SERVER: $SERVER_CN" |tee /key/strongswan.log
fi

	echo
	echo "Start ****"
	. /iptables.sh
	/usr/sbin/xl2tpd
	exec "$@"

else

	echo -e "
	Example
			docker run -d --restart always --privileged \\
			-v /docker/strongswan:/key \\
			--network=host \\
			-e VPN_USER=[jiobxn] \\
			-e VPN_PASS=<123456> \\
			-e VPN_PSK=[jiobxn.com] \\
			-e P12_PASS=[jiobxn.com] \\
			-e SERVER_CN=<SERVER_IP> \\
			-e CLIENT_CN=["strongSwan VPN"] \\
			-e CA_CN=["strongSwan CA"] \\
			-e IP_RANGE=[10.11.0] \\
			--hostname strongswan \\
			--name strongswan strongswan
	"
fi

#IOS Client:
# L2TP: user+pass+psk
# IPSec: user+pass+psk or user+pass+strongswan.p12, Note: Server is SERVER_CN
# IKEv2: user+pass+ca.crt, Note: Remote ID is SERVER_CN, Local ID is user

#Windows Client:
# L2TP: user+pass+psk, --network=host
# IKEv2: user+pass+ca.crt or user+pass+ca.crt+strongswan.p12, Note: Server is SERVER_CN. Certificate manage: certmgr.msc

#Windows 10 BUG:
# C:\Users\admin>powershell               #to PS Console
# PS C:\Users\jiobx> get-vpnconnection    #Show IKEv2 vpn connection name
# PS C:\Users\jiobx> set-vpnconnection "IKEv2-VPN-Name" -splittunneling $false    #Stop split tunneling
# PS C:\Users\jiobx> get-vpnconnection    #list
# PS C:\Users\jiobx> exit