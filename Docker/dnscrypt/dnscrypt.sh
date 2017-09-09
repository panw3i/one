#!/bin/bash
set -e

if [ "$1" = 'dnscrypt' ]; then

: ${CERT_DAY:="365"}
: ${SERVER_LISTEN:="0.0.0.0:5443"}
: ${CLIENT_LISTEN:="0.0.0.0:53"}
: ${BIND_VERSION:="windows 2003 DNS"}
: ${BIND_LOG_SIZE:="100m"}
: ${BIND_LISTEN:="any;"}
: ${BIND_ALLOW_QUERY:="any;"}


if [ ! -f /usr/bin/dnscrypt ]; then
	#bind
	init_bind() {
		sed -i '/recursion yes;/ a \\n\        \/* #jiobxn.com# *\/' /etc/named.conf
		sed -i '/#jiobxn.com#/ a \        version  "'"$BIND_VERSION"'";' /etc/named.conf
		sed -i 's/127.0.0.1;/'$BIND_LISTEN'/' /etc/named.conf
		sed -i 's/localhost;/'$BIND_ALLOW_QUERY'/' /etc/named.conf

		[ $BIND_FORWARDERS ] && sed -i '/#jiobxn.com#/ a \\n\        forwarders   { '$BIND_FORWARDERS' };' /etc/named.conf
		[ $BIND_CACHE_SIZE ] && sed -i '/#jiobxn.com#/ a \\n\        max-cache-size '$BIND_CACHE_SIZE';' /etc/named.conf
		
		if [ $BIND_QUERY_LOG ]; then
			sed -i '/logging {/ a \        channel query_log {\n\            file "data/query.log" versions 3 size '$BIND_LOG_SIZE';\n\            severity info;\n\            print-time yes;\n\            print-category   yes;\n\        };' /etc/named.conf
			sed -i '/logging {/ a \        category queries {\n\            query_log;\n\        };' /etc/named.conf
		fi
	}

	#Cisco OpenDNS
	if [ "$CLIENT_UPSTREAM" == "CISCO" ]; then
		SERVER_DOMAIN="opendns.com"
		CLIENT_UPSTREAM="208.67.220.220"
		PROVIDER_KEY="B735:1140:206F:225D:3E2B:D822:D7FD:691E:A1C3:3CC8:D666:8D0C:BE04:BFAB:CA43:FB79"
	fi

	#Cisco OpenDNS,Block websites not suitable for children
	if [ "$CLIENT_UPSTREAM" == "HOME" ]; then
		SERVER_DOMAIN="opendns.com"
		CLIENT_UPSTREAM="208.67.220.123"
		PROVIDER_KEY="B735:1140:206F:225D:3E2B:D822:D7FD:691E:A1C3:3CC8:D666:8D0C:BE04:BFAB:CA43:FB79"
	fi

	#server
	if [ "$SERVER_UPSTREAM" -a "$SERVER_DOMAIN" ]; then
		cd /key/
		if [ ! -f /key/dnscrypt.key -a ! -f /key/dnscrypt.cert -a ! -f /key/public.key ]; then
			dnscrypt-wrapper --gen-provider-keypair &>/dev/null
			dnscrypt-wrapper --gen-crypt-keypair --crypt-secretkey-file=dnscrypt.key &>/dev/null
			dnscrypt-wrapper --gen-cert-file --crypt-secretkey-file=dnscrypt.key --provider-cert-file=dnscrypt.cert --provider-publickey-file=public.key --provider-secretkey-file=secret.key --cert-file-expire-days=$CERT_DAY &>/dev/null
		fi

		echo "$SERVER_DOMAIN" |tee dnscrypt.log
		dnscrypt-wrapper --show-provider-publickey --provider-publickey-file public.key |tee -a dnscrypt.log
		dnscrypt-wrapper --show-provider-publickey-dns-records --provider-cert-file dnscrypt.cert |grep '"DNSC' |tee -a dnscrypt.log
		echo "Public server: https://github.com/jedisct1/dnscrypt-proxy/blob/master/dnscrypt-resolvers.csv" |tee -a dnscrypt.log
		\cp /usr/local/share/dnscrypt-proxy/dnscrypt-resolvers.csv .

		echo "/usr/sbin/named -u named -c /etc/named.conf" >/usr/bin/dnscrypt
		echo "dnscrypt-wrapper --resolver-address=$SERVER_UPSTREAM --listen-address=$SERVER_LISTEN --provider-name=2.dnscrypt-cert.$SERVER_DOMAIN --crypt-secretkey-file=dnscrypt.key --provider-cert-file=dnscrypt.cert" >>/usr/bin/dnscrypt
	fi

	#client
	if [ "$CLIENT_UPSTREAM" -a "$PROVIDER_KEY" -a "$SERVER_DOMAIN" ]; then
		echo "dnscrypt-proxy --local-address=$CLIENT_LISTEN --resolver-address=$CLIENT_UPSTREAM --provider-name=2.dnscrypt-cert.$SERVER_DOMAIN --provider-key=$PROVIDER_KEY" >/usr/bin/dnscrypt
	fi

	#default
	if [ -z "$SERVER_UPSTREAM" -a -z "$CLIENT_UPSTREAM" ]; then
		echo "/usr/sbin/named -u named -c /etc/named.conf -f" >/usr/bin/dnscrypt
	fi

	#chinadns
	if [ "$CHINADNS" -a "$CLIENT_UPSTREAM" -a "$PROVIDER_KEY" -a "$SERVER_DOMAIN" ]; then
		echo "/usr/sbin/named -u named -c /etc/named.conf" >/usr/bin/dnscrypt
		echo "dnscrypt-proxy --local-address=0.0.0.0:54 --resolver-address=$CLIENT_UPSTREAM --provider-name=2.dnscrypt-cert.$SERVER_DOMAIN --provider-key=$PROVIDER_KEY -d" >>/usr/bin/dnscrypt
		echo "chinadns -c /key/chnroute.txt -b 0.0.0.0 -p 53 -s '127.0.0.1:54,127.0.0.1:55' -d -v" >>/usr/bin/dnscrypt

		sed -i 's/port 53/port 55/g' /etc/named.conf

		if [ ! -f /key/chnroute.txt ]; then
			grep "CN|ipv4" /etc/delegated-apnic-latest |awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' >/key/chnroute.txt
		fi
	fi

	init_bind
	chmod +x /usr/bin/dnscrypt
fi

	echo "Start ****"
	exec $@
else
	echo -e "
	Example:
				docker run -d \\
				-v /docker/dnscrypt:/key \\
				-p 5443:5443/udp \\
				-p 53:53/udp \\
				-e CERT_DAY=[365] \\
				-e SERVER_DOMAIN=<jiobxn.com> \\
				-e SERVER_LISTEN=[0.0.0.0:5443] \\
				-e SERVER_UPSTREAM=<8.8.8.8:53> \\
				-e CLIENT_LISTEN=[0.0.0.0:53] \\
				-e CLIENT_UPSTREAM=<"server address" | CISCO | HOME> \\
				-e PROVIDER_KEY=<Provider public key>
				-e CHINADNS=<Y> \\
				-e BIND_VERSION=["windows 2003 DNS"] \\
				-e BIND_LOG_SIZE=[100m] \\
				-e BIND_LISTEN=["any;"] \\
				-e BIND_ALLOW_QUERY=["any;"] \\
				-e BIND_FORWARDERS=<8.8.8.8;> \\
				-e BIND_CACHE_SIZE=[32m] \\
				-e BIND_QUERY_LOG=<Y> \\
				--hostname dns --name dns dnscrypt
	"
fi
