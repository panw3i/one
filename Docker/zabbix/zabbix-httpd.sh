#!/bin/bash
set -e

if [ "$1" = 'httpd' ]; then

: ${PHP_PORT:=9000}
: ${PHP_PATH:=/var/www}
: ${ZBX_DB_PORT:=3306}
: ${ZBX_DB_USER:=zabbix}
: ${ZBX_DB_PASSWORD:=newpass}
: ${ZBX_DB_DATABASE:=zabbix}

if [ -z "$(grep "redhat.xyz" /etc/httpd/conf/httpd.conf)" ]; then
		echo "Initialize httpd"
		#Initialize httpd
		cat >>/etc/httpd/conf/httpd.conf <<-END
		#redhat.xyz
		ServerName localhost
		AddDefaultCharset UTF-8
		#
		<IfModule deflate_module>  
		AddOutputFilterByType DEFLATE all  
		SetOutputFilter DEFLATE  
		</ifModule>  
		END

		#php server
		if [ $PHP_SERVER ]; then
			sed -i 's/index.html/index.html index.php/' /etc/httpd/conf/httpd.conf
			cat >>/etc/httpd/conf/httpd.conf <<-END
			#
			<LocationMatch ^(.*\.php)$>
			ProxyPass fcgi://$PHP_SERVER:$PHP_PORT$PHP_PATH
			ProxyErrorOverride On
			</LocationMatch>
			END
		else
			echo "error. Not specified PHP server."
			exit 1
		fi


	#Initialize zabbix
	if [ "$ZBX_DB_SERVER" ]; then
		#Initialize databases
		DB=$(MYSQL_PWD="$ZBX_DB_PASSWORD" mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER -e "use $ZBX_DB_DATABASE; SELECT 113;" |awk 'NR!=1{print $1,$2}')
		TAB=$(MYSQL_PWD="$ZBX_DB_PASSWORD" mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER -e "use $ZBX_DB_DATABASE; show tables;" |awk 'NR!=1{print $1,$2}' |wc -l)
		[ $? -eq 1 ] && echo "Mysql connection failed .." && exit 1
		
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
		if [ -d "/var/www/html/zabbix" ]; then
			echo "/var/www/html/zabbix already exists, skip"
		else
			DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
			ZBX_SERVER=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
			[ -z $ZBX_SERVER ] && ZBX_SERVER=localhost
			
			\cp -a /usr/local/zabbix/php /var/www/html/zabbix
			chown -R apache.apache /var/www/html/zabbix/

			sed -i "/check for deprecated PHP 5.6.0 option 'always_populate_raw_post_data'/,+4d" /var/www/html/zabbix/include/classes/setup/CFrontendSetup.php
			sed -i "/public function checkPhpAlwaysPopulateRawPostData/,+11d" /var/www/html/zabbix/include/classes/setup/CFrontendSetup.php
			sed -i '/$last = strtolower(substr($val, -1));/a$val = substr($val,0,-1);' /var/www/html/zabbix/include/func.inc.php

			\cp /usr/share/fonts/wqy-zenhei/wqy-zenhei.ttc /var/www/html/zabbix/fonts/DejaVuSans.ttf
			zh_CN=$(grep -n zh_CN /var/www/html/zabbix/include/locales.inc.php |awk -F: '{print $1}')
			sed -i ''$zh_CN's/false/true/' /var/www/html/zabbix/include/locales.inc.php

			cat >>/var/www/html/zabbix/conf/zabbix.conf.php <<-END
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
			\$ZBX_SERVER_PORT = '10051';
			\$ZBX_SERVER_NAME = 'admin';
			\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
			?>
			END

			sed -i "s/\['PORT'\]     = '3306'/\['PORT'\]     = '0'/g" /var/www/html/zabbix/conf/zabbix.conf.php
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
				docker run -d --restart always [--privileged] \\
				-v /docker/www:/var/www/html \\
				-p 11080:80 \\
				-p 11443:443 \\
				-e PHP_SERVER=<redhat.xyz> \\
				-e PHP_PORT=[9000] \\
				-e PHP_PATH=[/var/www] \\
				-e ZBX_DB_SERVER=<redhat.xyz> \\
				-e ZBX_DB_PORT=[3306] \\
				-e ZBX_DB_USER=[zabbix] \\
				-e ZBX_DB_PASSWORD=[newpass] \\
				-e ZBX_DB_DATABASE=[zabbix] \\
				--hostname zabbix-httpd \\
				--name zabbix-httpd zabbix-httpd
	"
fi
