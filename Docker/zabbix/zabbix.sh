#!/bin/bash
set -e

if [ "$1" = 'httpd' ]; then

: ${ZBX_DB_PORT:=3306}
: ${ZBX_DB_USER:=zabbix}
: ${ZBX_DB_PASSWORD:=newpass}
: ${ZBX_DB_DATABASE:=zabbix}

if [ -z "$(grep "redhat.xyz" /etc/httpd/conf/httpd.conf)" ]; then
	echo "Initialize zabbix"
	#Initialize zabbix
	if [ "$ZBX_DB_SERVER" ]; then
		#Initialize databases
		DB=$(mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER -p$ZBX_DB_PASSWORD -e "use $ZBX_DB_DATABASE; SELECT 113;" 2>/dev/null |awk 'NR!=1{print $1,$2}' |sed 's/ //')
		DB=$(mysql -h$ZBX_DB_SERVER -P$ZBX_DB_PORT -u$ZBX_DB_USER -p$ZBX_DB_PASSWORD -e "use $ZBX_DB_DATABASE; SELECT 113;" 2>/dev/null |awk 'NR!=1{print $1,$2}' |sed 's/ //')
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

		#Initialize php
                localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 2>/dev/null || echo
                localedef -v -c -i zh_CN -f UTF-8 zh_CN.UTF-8 2>/dev/null || echo
                        
                sed -i 's/;date.timezone =/date.timezone = PRC/' /etc/php.ini 
                sed -i 's/max_input_time = 60/max_input_time = 300/' /etc/php.ini 
                sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php.ini 
                sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php.ini 
                sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 32M/' /etc/php.ini 
                sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php.ini 

		#Initialize web
		echo -e "#redhat.xyz\nServerName localhost" >>/etc/httpd/conf/httpd.conf
		if [ -d "/var/www/html/zabbix" ]; then
			echo "/var/www/html/zabbix already exists, skip"
		else
			\cp -a /usr/local/zabbix/php /var/www/html/zabbix
			chown -R apache.apache /var/www/html/zabbix/

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
			\$ZBX_SERVER      = 'localhost';
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
				-e ZBX_DB_SERVER=<redhat.xyz> \\
				-e ZBX_DB_PORT=[3306] \\
				-e ZBX_DB_USER=[zabbix] \\
				-e ZBX_DB_PASSWORD=[newpass] \\
				-e ZBX_DB_DATABASE=[zabbix] \\
				--hostname zabbix \\
				--name zabbix zabbix
	"
fi
