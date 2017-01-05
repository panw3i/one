#!/bin/bash
set -e

if [ "$1" = 'nginx' ]; then

: ${NGX_PASS:=$(pwmake 64)}
: ${PHP_PATH:=/var/www}
: ${HTTP_PORT:=80}
: ${HTTPS_PORT:=443}
: ${NGX_CODING:=utf-8}


if [ -z "$(grep "redhat.xyz" /etc/nginx/nginx.conf)" ]; then
	echo "Initialize nginx"
	if [ "$DEFAULT_SERVER" ]; then
		default_server=""
	else
		default_server="#"
	fi
	
	
	if [ "$FULL_HTTPS" = "Y" ]; then
		default_https=""
	else
		default_https="#"
	fi
	
	
	if [ "$NGX_USER" ]; then
		enable_status=""
	else
		enable_status="#"
	fi
	
	
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/{server.crt,server.key} /etc/nginx/
	else
		openssl genrsa -out /etc/nginx/server.key 4096 2>/dev/null
		openssl req -new -key /etc/nginx/server.key -out /etc/nginx/server.csr -subj "/C=CN/L=London/O=Company Ltd/CN=nginx-docker" 2>/dev/null
		openssl x509 -req -days 3650 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>/dev/null
	fi
    

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
	keepalive_timeout  70;

	charset $NGX_CODING;

	client_max_body_size 0;
	autoindex on;
	server_tokens off;

	#proxy_cache cache1;
	proxy_cache_key \$scheme\$proxy_host\$request_uri\$cookie_user\$is_args\$args;
	#proxy_cache_path /tmp/proxy_cache levels=1:2 keys_zone=cache1:1m;
	proxy_cache_valid any      1m;
	proxy_max_temp_file_size 1024m;
	#proxy_temp_path /tmp/proxy_temp 1 2 3;

	#fastcgi_cache cache2;
	fastcgi_cache_key \$host\$request_uri;
	#fastcgi_cache_path /tmp/fastcgi_cache levels=1:2 keys_zone=cache2:1m;
	fastcgi_cache_valid any      1m;
	fastcgi_max_temp_file_size 1024m;
	#fastcgi_temp_path /tmp/fastcgi_temp 1 2 3;

	gunzip on;
	gzip  on;
	gzip_comp_level 6;
	gzip_proxied any;
	gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/x-httpd-php image/jpeg image/gif image/png;
	gzip_vary on;

	#upstream

		include /etc/nginx/conf.d/*.conf;

	   $default_server server {
	   $default_server         listen       $HTTP_PORT  default_server;
	   $default_server         server_name  _;
	   $default_server         rewrite ^(.*) http://$DEFAULT_SERVER:$HTTP_PORT permanent;
	   $default_server }
	}

	daemon off;
	END

 
 
	#SERVER
	cat >/etc/nginx/conf.d/default.conf <<-END
	server {
	    listen       $HTTP_PORT;
	    listen       $HTTPS_PORT ssl;
	    server_name localhost;
		
	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:1m;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;

	    location / {
	        root   /usr/share/nginx/html;
	        index  index.html index.htm;
	    }

	$enable_status    location ~ /basic_status {
	$enable_status        stub_status;
	$enable_status        auth_basic           "Nginx Stats";
	$enable_status        auth_basic_user_file /etc/nginx/.htpasswd;
	$enable_status    }
	}
	END



	php_server() {
	cat >/etc/nginx/conf.d/php.conf <<-END
	server {
	    listen       $HTTP_PORT;
	    listen       $HTTPS_PORT ssl;
	    #server_name

	    $default_https if (\$scheme = http) { return 301 https://\$host\$request_uri;}
		
	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:1m;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;

	    location / {
	        root   /usr/share/nginx/html;
	        index  index.php index.html index.htm;
	        try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
	    }

	    #php_alias

	    location ~ \.php$ {
	        fastcgi_pass   fastcgi-lb;
	        fastcgi_index  index.php;
	        fastcgi_param  SCRIPT_FILENAME  $PHP_PATH\$fastcgi_script_name;
	        include        fastcgi_params;
	        fastcgi_read_timeout    300;
	        fastcgi_connect_timeout 300;
	    }

	$enable_status    location ~ /basic_status {
	$enable_status        stub_status;
	$enable_status        auth_basic           "Nginx Stats";
	$enable_status        auth_basic_user_file /etc/nginx/.htpasswd;
	$enable_status    }

	    location ~ /\.ht {
	        deny  all;
	    }
	}
	END
	}



	java_server() {
	cat >/etc/nginx/conf.d/java.conf <<-END
	server {
	    listen       $HTTP_PORT;
	    listen       $HTTPS_PORT ssl;
	    #server_name
	    
	    $default_https if (\$scheme = http) { return 301 https://\$host\$request_uri;}
	    
	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:1m;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    location / {
	        root   /usr/share/nginx/html;
	        index  index.jsp index.html index.htm;
	    }

	    #java_alias

	    location ~ .(jsp|jspx|do)?$ {
	        proxy_pass http://java-lb;
	        proxy_http_version 1.1;
	        proxy_read_timeout      300;
	        proxy_connect_timeout   300;
	        proxy_redirect     off;
	        proxy_set_header   Host              \$host;
	        proxy_set_header   X-Real-IP         \$remote_addr;
	        proxy_set_header   X-Forwarded-By    \$server_addr:\$server_port;
	        proxy_set_header   X-Forwarded-Proto \$scheme;
	        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
	        proxy_set_header   Referer           \$host;
	        proxy_set_header   Accept-Encoding  "";
	    }

	$enable_status    location ~ /basic_status {
	$enable_status        stub_status;
	$enable_status        auth_basic           "Nginx Stats";
	$enable_status        auth_basic_user_file /etc/nginx/.htpasswd;
	$enable_status    }

	    location ~ /\.ht {
	        deny  all;
	    }
	}
	END
	}



	proxy_server() {
	cat >>/etc/nginx/conf.d/proxy_$n.conf <<-END
	server {
	    listen       $HTTP_PORT;
	    listen       $HTTPS_PORT ssl;
	    #server_name

	    $default_https if (\$scheme = http) { return 301 https://\$host\$request_uri;}

	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;
	    ssl_session_cache shared:SSL:1m;
	    ssl_session_timeout  5m;
	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    location / {
	        proxy_pass http://proxy-lb-$n;
	        proxy_http_version 1.1;
	        proxy_read_timeout      300;
	        proxy_connect_timeout   300;
	        proxy_redirect     off;
	        proxy_set_header   Host              \$proxy_host;
	        proxy_set_header   X-Real-IP         \$remote_addr;
	        proxy_set_header   X-Forwarded-By    \$server_addr:\$server_port;
	        proxy_set_header   X-Forwarded-Proto \$scheme;
	        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
	        proxy_set_header   Referer           \$host;
	        proxy_set_header   Accept-Encoding  "";
	        sub_filter_once  off;
	        sub_filter_types * ;
	        sub_filter \$proxy_host \$host;
	    }

	$enable_status    location ~ /basic_status {
	$enable_status        stub_status;
	$enable_status        auth_basic           "Nginx Stats";
	$enable_status        auth_basic_user_file /etc/nginx/.htpasswd;
	$enable_status    }
	}
	END
	}



	if [ "$PHP_SERVER" ]; then
		php_server
		sed -i '/#upstream/a upstream fastcgi-lb {\n}\n' /etc/nginx/nginx.conf

		if [ -n "$(echo $PHP_SERVER |grep \|)" ]; then
			for i in $(echo $PHP_SERVER |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
				sed -i '/#server_name/ a \    server_name '$i';' /etc/nginx/conf.d/php.conf
			done
			
			for i in $(echo $PHP_SERVER |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
				sed -i '/upstream fastcgi-lb/ a \        server '$i';' /etc/nginx/nginx.conf	
			done
		else
			sed -i '/#server_name/ a \    server_name localhost;' /etc/nginx/conf.d/php.conf
			
			for i in $(echo $PHP_SERVER |sed 's/,/\n/g'); do
				sed -i '/upstream fastcgi-lb/ a \        server '$i';' /etc/nginx/nginx.conf	
			done
			\rm /etc/nginx/conf.d/default.conf
		fi
	fi


	if [ $PHP_ALIAS ]; then
		for i in $(echo "$PHP_ALIAS" |sed 's/;/\n/g'); do
			if [ -n "$(echo $i |grep ',')" ]; then
				sed -i '/#php_alias/ a \    location '$(echo $i |awk -F, '{print $1}')' {\n\        alias '$(echo $i |awk -F, '{print $2}')';\n\    }\n' /etc/nginx/conf.d/php.conf
			fi
		done
	fi


	if [ "$JAVA_SERVER" ]; then
		java_server
		sed -i '/#upstream/a upstream java-lb {\n}\n' /etc/nginx/nginx.conf

		if [ "$TOMCAT_HTTPS" = "Y" ]; then
				sed -i 's/proxy_pass http/proxy_pass https/g' /etc/nginx/conf.d/java.conf
		fi

	
		if [ -n "$(echo $JAVA_SERVER |grep \|)" ]; then
			for i in $(echo $JAVA_SERVER |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
				sed -i '/#server_name/ a \    server_name '$i';' /etc/nginx/conf.d/java.conf
			done
			
			for i in $(echo $JAVA_SERVER |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
				sed -i '/upstream java-lb/ a \        server '$i';' /etc/nginx/nginx.conf	
			done
		else
			sed -i '/#server_name/ a \    server_name localhost;' /etc/nginx/conf.d/java.conf
			
			for i in $(echo $JAVA_SERVER |sed 's/,/\n/g'); do
				sed -i '/upstream java-lb/ a \        server '$i';' /etc/nginx/nginx.conf	
			done
			\rm /etc/nginx/conf.d/default.conf
		fi
	fi


	if [ $JAVA_ALIAS ]; then
		for i in $(echo "$JAVA_ALIAS" |sed 's/;/\n/g'); do
			if [ -n "$(echo $i |grep ',')" ]; then
				sed -i '/#java_alias/ a \    location '$(echo $i |awk -F, '{print $1}')' {\n\        alias '$(echo $i |awk -F, '{print $2}')';\n\    }\n' /etc/nginx/conf.d/java.conf
			fi
		done
	fi


	if [ "$PROXY_SERVER" ]; then
		n=0
		
		for i in $(echo "$PROXY_SERVER" |sed 's/;/\n/g'); do
			n=$(($n+1))
			proxy_server
		
			if [ "$PROXY_HTTPS" = "Y" ]; then
				sed -i 's/proxy_pass http/proxy_pass https/g' /etc/nginx/conf.d/proxy_$n.conf
			fi
		
		
			if [ -n "$(echo $i |grep '|')" ]; then
				for x in $(echo $i |awk -F'|' '{print $1}' |sed 's/,/\n/g'); do
					sed -i '/#server_name/ a \    server_name '$x';' /etc/nginx/conf.d/proxy_$n.conf
				done

				if [ -n "$(echo $i |awk -F'|' '{print $2}' |grep ",")" ]; then
					sed -i '/#upstream/a upstream proxy-lb-'$n' {\n}\n' /etc/nginx/nginx.conf

					for x in $(echo $i |awk -F'|' '{print $2}' |sed 's/,/\n/g'); do
						sed -i '/upstream proxy-lb-'$n'/ a \        server '$x';' /etc/nginx/nginx.conf
					done
				else
					sed -i 's/proxy-lb-'$n'/'$(echo $i |awk -F'|' '{print $2}')'/' /etc/nginx/conf.d/proxy_$n.conf
				fi
			else
				sed -i '/#server_name/ a \    server_name localhost;' /etc/nginx/conf.d/proxy_$n.conf

				if [ -n "$(echo $i |grep ",")" ]; then
					sed -i '/#upstream/a upstream proxy-lb-'$n' {\n}\n' /etc/nginx/nginx.conf

					for x in $(echo $i |sed 's/,/\n/g'); do
						sed -i '/upstream proxy-lb-'$n'/ a \        server '$x';' /etc/nginx/nginx.conf
					done
				else
					sed -i 's/proxy-lb-'$n'/'$i'/' /etc/nginx/conf.d/proxy_$n.conf
				fi
				\rm /etc/nginx/conf.d/default.conf
			fi
		done
	fi


	if [ "$PROXY_HEADER" ]; then
		for i in $(echo $PROXY_HEADER |sed 's/;/\n/g') ;do
			if [ -n "$(echo $i |grep '|')" ]; then
				n=$(echo $i |awk -F'|' '{print $1}')
				sed -i 's/proxy_host;/'$(echo $i |awk -F'|' '{print $2}')';/g' /etc/nginx/conf.d/proxy_$n.conf
			else
				sed -i 's/proxy_host;/'$i';/g' /etc/nginx/conf.d/proxy_*.conf
			fi
		done
	fi


	if [ "$IP_HASH" = "Y" ]; then
		sed -i '/upstream / a ip_hash;' /etc/nginx/nginx.conf
	fi


	if [ "$NGX_USER" ]; then
		echo "$NGX_USER:$(openssl passwd -apr1 $NGX_PASS)" >> /etc/nginx/.htpasswd
		echo "Nginx user AND password: $NGX_USER  $NGX_PASS"
	fi
fi

	echo "Start ****"
	exec "$@"
else

	echo -e " 
	Example:
				docker run -d --restart always \\
				-v /docker/www:/usr/share/nginx/html \\
				-v /docker/upload:/upload \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-e HTTP_PORT=80 \\
				-e HTTPS_PORT=443 \\
				-e NGX_CODING=[utf-8] \\
				-e PHP_SERVER=<'php.redhat.xyz|10.0.0.11:9000,10.0.0.12:9000'> \\
				-e PHP_PATH=[/var/www] \\
				-e JAVA_SERVER=<'java.redhat.xyz|10.0.0.21:1080,10.0.0.22:2080'> \\
				-e TOMCAT_HTTPS=<Y> \\
				-e PROXY_SERVER=<'redhat.xyz,www.redhat.xyz|10.0.0.31,10.0.0.41;b.redhat.xyz|www.baidu.com'> \\
				-e PROXY_HTTPS=<Y> \\
				-e PROXY_HEADER=<2|host;http_host> \\
				-e FULL_HTTPS=<Y> \\
				-e DEFAULT_SERVER=<redhat.xyz> \\
				-e IP_HASH=<Y> \\
				-e PHP_ALIAS=<'/upload,/upload'> \\
				-e JAVA_ALIAS=<'/upload,/upload'> \\
				-e NGX_USER=<admin> \\
				-e NGX_PASS=<redhat> \\
				--hostname nginx-rpm \\
				--name nginx-rpm nginx-rpm
	"	
fi
