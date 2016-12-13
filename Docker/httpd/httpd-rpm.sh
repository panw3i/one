#!/bin/bash
set -e

if [ "$1" = 'httpd' ]; then

: ${APC_PASS:=$(pwmake 64)}
: ${PHP_PORT:=9000}
: ${PHP_PATH:=/var/www}
: ${HTTP_PORT:=80}
: ${HTTPS_PORT:=443}

if [ -z "$(grep "redhat.xyz" /etc/httpd/conf/httpd.conf)" ]; then
	echo "Initialize httpd"
	#http port
	if [ "$HTTP_PORT" -ne "80"  ]; then
		sed -i 's/Listen 80/Listen '$HTTP_PORT'/g' /etc/httpd/conf/httpd.conf
	fi
	
	#https port
	if [ "$HTTPS_PORT" -ne "443"  ]; then
		sed -i 's/Listen 443/Listen '$HTTPS_PORT'/g' /etc/httpd/conf.d/ssl.conf
		sed -i 's/_default_:443/_default_:'$HTTPS_PORT'/g' /etc/httpd/conf.d/ssl.conf
	fi
	
	#key
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/server.crt /etc/pki/tls/certs/localhost.crt
		\cp /key/server.key /etc/pki/tls/private/localhost.key
	fi
	
	#gzip
	cat >>/etc/httpd/conf/httpd.conf <<-END
	#
	#redhat.xyz
	ServerName localhost
	AddDefaultCharset UTF-8

	<IfModule deflate_module>  
	AddOutputFilterByType DEFLATE all  
	SetOutputFilter DEFLATE  
	</ifModule>  
	END

	#php
	if [ $PHP_SERVER ]; then
		sed -i 's/index.html/index.php index.html/' /etc/httpd/conf/httpd.conf
		cat >>/etc/httpd/conf/httpd.conf <<-END
		#
		<LocationMatch ^(.*\.php)$>
		ProxyPass fcgi://$PHP_SERVER:$PHP_PORT$PHP_PATH
		ProxyErrorOverride On
		</LocationMatch>
		END
	fi
	
	#alias
	if [ $WWW_ALIAS ]; then
		for i in $(echo "$WWW_ALIAS" |sed 's/;/\n/g'); do
			if [ -n "$(echo $i |grep ',')" ]; then
				echo -e "#alias\nAlias \"$(echo $i |awk -F, '{print $1}')\" \"$(echo $i |awk -F, '{print $2}')\"\n<Directory \"$(echo $i |awk -F, '{print $2}')\">\n  Require all granted\n</Directory>" >>/etc/httpd/conf/httpd.conf
			fi
		done
	fi
	
	#default server
	if [ "$SERVER_NAME" ]; then
		cat >>/etc/httpd/conf/httpd.conf <<-END
		#
		<VirtualHost *:$HTTP_PORT>
		ServerName _default_
		Redirect / http://localhost:$HTTP_PORT
		</VirtualHost>
		
		<VirtualHost *:$HTTP_PORT>
		#server_name
		</VirtualHost>
		END
		
		sed -i '/VirtualHost _default_/i <VirtualHost *:'$HTTPS_PORT'>\n ServerName _default_\n Redirect / https://localhost:'$HTTPS_PORT'\n SSLEngine on\n SSLCertificateFile /etc/pki/tls/certs/localhost.crt\n SSLCertificateKeyFile /etc/pki/tls/private/localhost.key\n</VirtualHost>\n'  /etc/httpd/conf.d/ssl.conf
		
		for i in $(echo $SERVER_NAME |sed 's/,/\n/g') ;do
			sed -i '/#server_name/ a ServerAlias '$i'' /etc/httpd/conf/httpd.conf
			sed -i '/VirtualHost _default_/ a ServerAlias '$i'' /etc/httpd/conf.d/ssl.conf
		done

		sed -i 's/localhost/'$(echo $SERVER_NAME |awk -F, '{print $1}')'/g' /etc/httpd/conf/httpd.conf
		sed -i 's/localhost/'$(echo $SERVER_NAME |awk -F, '{print $1}')'/g' /etc/httpd/conf.d/ssl.conf
	fi
	
	#status
	if [ "$APC_USER" ]; then
		cat >>/etc/httpd/conf/httpd.conf <<-END
		#
		<Location /basic_status>
		AuthName "Apache stats"
		AuthType Basic
		AuthUserFile /etc/httpd/.htpasswd
		Require valid-user
		SetHandler server-status
		</Location>
		END
	
		if [ "$APC_USER" ]; then
			echo "$APC_USER:$(openssl passwd -apr1 $APC_PASS)" > /etc/httpd/.htpasswd
			echo "Apache user AND password: $APC_USER  $APC_PASS"
		fi
	fi
fi
	echo "Start ****"
	exec "$@"
else

    echo -e "
	Example:
				docker run -d --restart always \\
				-v /docker/www:/var/www/html \\
				-v /docker/upload:/upload \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-e HTTP_PORT=[80] \\
				-e HTTPS_PORT=[443] \\
				-e PHP_SERVER=<redhat.xyz> \\
				-e PHP_PORT=[9000] \\
				-e PHP_PATH=</var/www> \\
				-e SERVER_NAME=<www.redhat.xyz,redhat.xyz> \\
				-e WWW_ALIAS=<"/upload,/upload"> \\
				--hostname httpd-rpm \\
				--name httpd-rpm httpd-rpm
	"
fi