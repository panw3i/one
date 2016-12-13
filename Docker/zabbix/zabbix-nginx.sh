#!/bin/bash
set -e

if [ "$1" = 'nginx' ]; then

: ${PHP_PORT:=9000}
: ${PHP_PATH:=/var/www}
: ${ZBX_DB_PORT:=13306}
: ${ZBX_DB_USER:=zabbix}
: ${ZBX_DB_PASSWORD:=newpass}
: ${ZBX_DB_DATABASE:=zabbix}
: ${ZBX_PORT:=20051}
: ${ZBX_USER:=admin}

if [ -z "$(grep "redhat.xyz" /etc/nginx/nginx.conf)" ]; then

	if [ "$PHP_SERVER" ]; then
		echo "Initialize nginx"
	else
		echo "error. Not specified PHP server."
		exit 1
	fi

	openssl genrsa -out /etc/nginx/server.key 4096 2>/dev/null
	openssl req -new -key /etc/nginx/server.key -out /etc/nginx/server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=zabbix-docker" 2>/dev/null
	openssl x509 -req -days 3650 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>/dev/null


	#global
	cat >/etc/nginx/nginx.conf <<-END
	#redhat.xyz
	user  nginx;
	worker_processes  $(nproc);

	error_log  /var/log/nginx/error.log warn;
	pid        /var/run/nginx.pid;


	events {
		worker_connections  $((`nproc`*10240));
	}

	http {
		include       /etc/nginx/mime.types;
		default_type  application/octet-stream;

		log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
						'\$status \$body_bytes_sent "\$http_referer" '
						'"\$http_user_agent" "\$http_x_forwarded_for"';

		access_log  /var/log/nginx/access.log  main;

		sendfile        on;
		tcp_nopush      on;
		tcp_nodelay     on;
		keepalive_timeout  300;

		autoindex on;
		charset utf-8;
		server_names_hash_bucket_size 128;
		large_client_header_buffers 4 64k;
		client_max_body_size 512m;
		client_header_buffer_size 32k;
		client_body_buffer_size 512k;
		client_header_timeout 300s;
		client_body_timeout 300s;
		send_timeout 300s;

		gzip  on;
		gzip_buffers 16 8k;
		gzip_comp_level 6;
		gzip_min_length 1000;
		gzip_http_version 1.1;
		gzip_proxied any;
		gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/x-httpd-php image/jpeg image/gif image/png;
		gzip_vary on;

		proxy_http_version 1.1;
		proxy_buffer_size 64k;
		proxy_buffering on;
		proxy_buffers 4 64k;
		proxy_busy_buffers_size 128k;
		proxy_connect_timeout 300s;
		proxy_read_timeout 300s;
		proxy_send_timeout 300s;
		proxy_ignore_client_abort on;
		proxy_max_temp_file_size 0;
		proxy_headers_hash_max_size 64;

		include /etc/nginx/conf.d/*.conf;
	}
	daemon off;
	END

 
	#HTTP
	cat >/etc/nginx/conf.d/default.conf <<-END
	server {
		listen       80;
		server_name  localhost;

		location / {
			root   /usr/share/nginx/html;
			index  index.html index.php index.htm;
		}

		location ~ \.php$ {
			root           html;
			fastcgi_pass   $PHP_SERVER:$PHP_PORT;
			fastcgi_index  index.php;
			fastcgi_param  SCRIPT_FILENAME  $PHP_PATH\$fastcgi_script_name;
			include        fastcgi_params;
		}
	}
	END
	
	
	#HTTPS
	cat >/etc/nginx/conf.d/nginx-ssl.conf <<-END
	server {
		listen       443 ssl;
		server_name  localhost;

		ssl_certificate      /etc/nginx/server.crt;
		ssl_certificate_key  /etc/nginx/server.key;

		ssl_session_cache shared:SSL:1m;
		ssl_session_timeout  5m;

		ssl_ciphers  HIGH:!aNULL:!MD5;
		ssl_prefer_server_ciphers   on;

		location / {
			root   /usr/share/nginx/html;
			index  index.html index.php index.htm;
		}
	
		location ~ \.php$ {
			root           html;
			fastcgi_pass   $PHP_SERVER:$PHP_PORT;
			fastcgi_index  index.php;
			fastcgi_param  SCRIPT_FILENAME  $PHP_PATH\$fastcgi_script_name;
			include        fastcgi_params;
		}

	}
	END

		WWW_PATH="/usr/share/nginx/html/"
		WWW_USER="nginx"

	#Initialize zabbix
	if [ "$ZBX_DB_SERVER" ]; then
		#Initialize databases
		DB=$(MYSQL_PWD="$ZBX_DB_PASSWORD" mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER -e "use $ZBX_DB_DATABASE; SELECT 113;" |awk 'NR!=1{print $1,$2}')
		TAB=$(MYSQL_PWD="$ZBX_DB_PASSWORD" mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER -e "use $ZBX_DB_DATABASE; show tables;" |awk 'NR!=1{print $1,$2}' |wc -l)
		if [ "$DB" -eq 113 ]; then
			if [ "$TAB" -gt 100 ]; then
				echo "$ZBX_DB_DATABASE table already exists, skip"
			else
				echo "Initialize databases"
				MYSQL_PWD="$ZBX_DB_PASSWORD" mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER $ZBX_DB_DATABASE < /usr/local/zabbix/mysql/schema.sql
				MYSQL_PWD="$ZBX_DB_PASSWORD" mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER $ZBX_DB_DATABASE < /usr/local/zabbix/mysql/images.sql
				MYSQL_PWD="$ZBX_DB_PASSWORD" mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER $ZBX_DB_DATABASE < /usr/local/zabbix/mysql/data.sql
			fi
		else
			echo "$ZBX_DB_DATABASE Write Failed"
			exit 1
		fi

		sed -i 's/# DBHost=localhost/DBHost='$ZBX_DB_SERVER'/' /usr/local/zabbix/etc/zabbix_server.conf
		sed -i 's/DBUser=root/DBUser='$ZBX_DB_USER'/' /usr/local/zabbix/etc/zabbix_server.conf
		sed -i 's/# DBPassword=/DBPassword='$ZBX_DB_PASSWORD'/' /usr/local/zabbix/etc/zabbix_server.conf
		sed -i 's/# DBPort=3306/DBPort='$ZBX_DB_PORT'/' /usr/local/zabbix/etc/zabbix_server.conf

		sed -i 's/# JavaGateway=/JavaGateway=127.0.0.1/' /usr/local/zabbix/etc/zabbix_server.conf
		sed -i 's/# JavaGatewayPort=10052/JavaGatewayPort=10052/' /usr/local/zabbix/etc/zabbix_server.conf
		sed -i 's/# StartJavaPollers=0/StartJavaPollers=5/' /usr/local/zabbix/etc/zabbix_server.conf

		#Initialize web php
		if [ -d "$WWW_PATH/zabbix" ]; then
			echo "$WWW_PATH/zabbix already exists, skip"
		else
			DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
			if [ -z $ZBX_SERVER ]; then
				ZBX_SERVER=$(curl -s https://httpbin.org/ip |awk -F\" 'NR==2{print $4}')
			fi
			
			if [ -z $ZBX_SERVER ]; then
				ZBX_SERVER=$(curl -s https://showip.net/)
			fi
			
			if [ -z $ZBX_SERVER ]; then
				ZBX_SERVER=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
			fi
			
			\cp -a /usr/local/zabbix/php $WWW_PATH/zabbix
			chown -R $WWW_USER.$WWW_USER $WWW_PATH/zabbix/

			sed -i "/check for deprecated PHP 5.6.0 option 'always_populate_raw_post_data'/,+4d" $WWW_PATH/zabbix/include/classes/setup/CFrontendSetup.php
			sed -i "/public function checkPhpAlwaysPopulateRawPostData/,+11d" $WWW_PATH/zabbix/include/classes/setup/CFrontendSetup.php

			\cp /usr/share/fonts/wqy-zenhei/wqy-zenhei.ttc $WWW_PATH/zabbix/fonts/DejaVuSans.ttf
			zh_CN=$(grep -n zh_CN $WWW_PATH/zabbix/include/locales.inc.php |awk -F: '{print $1}')
			sed -i ''$zh_CN's/false/true/' $WWW_PATH/zabbix/include/locales.inc.php

			cat >>$WWW_PATH/zabbix/conf/zabbix.conf.php <<-END
			<?php
			// Zabbix GUI configuration file.
			global \$DB;

			\$DB['TYPE']     = 'MYSQL';
			\$DB['SERVER']   = '$ZBX_DB_SERVER';
			\$DB['PORT']     = '$ZBX_DB_PORT';
			\$DB['DATABASE'] = '$ZBX_DB_DATABASE';
			\$DB['USER']     = '$ZBX_DB_USER';
			\$DB['PASSWORD'] = '$ZBX_DB_PASSWORD';

			// Schema name. Used for IBM DB2 and PostgreSQL.
			\$DB['SCHEMA'] = '';

			\$ZBX_SERVER      = '$ZBX_SERVER';
			\$ZBX_SERVER_PORT = '$ZBX_PORT';
			\$ZBX_SERVER_NAME = '$ZBX_USER';

			\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
			?>
			END
			
			sed -i "s/\['PORT'\]     = '3306'/\['PORT'\]     = '0'/g" $WWW_PATH/zabbix/conf/zabbix.conf.php
		fi
	else
		echo -e "error. Not specified MYSQL server."
	fi
fi

	echo "Start ****"
	zabbix_server
	zabbix_agentd
	bash /usr/local/zabbix/sbin/zabbix_java/startup.sh
	exec "$@"
else

	echo -e "
	Example:
				docker run -d --restart always --privileged \\
				-v /docker/www:/usr/share/nginx/html \\
				-p 11080:80 \\
				-p 11443:443 \\
				-p 20051:10051 \\
				-e PHP_SERVER=<redhat.xyz> \\
				-e PHP_PORT=[9000] \\
				-e PHP_PATH=[/var/www] \\
				-e ZBX_DB_SERVER=<redhat.xyz> \\
				-e ZBX_DB_PORT=[13306] \\
				-e ZBX_DB_USER=[zabbix] \\
				-e ZBX_DB_DATABASE=[zabbix] \\
				-e ZBX_SERVER=[SERVER_IP] \\
				-e ZBX_PORT=[20051] \\
				-e ZBX_USER=[admin] \\
				--hostname zabbix-nginx \\
				--name zabbix-nginx zabbix-nginx
	"
fi