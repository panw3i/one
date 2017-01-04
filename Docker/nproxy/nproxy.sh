#!/bin/bash
set -e

if [ "$1" = 'nginx' ]; then

: ${TAG:="-"}
: ${NGX_PASS:=$(pwmake 64)}
: ${NGX_DOMAIN:=example.com}
: ${NGX_DNS=8.8.8.8}
: ${HTTP_PORT:=80}
: ${HTTPS_PORT:=443}
: ${CACHE_TIME:=30m}
: ${MAX_CACHE:=1000m}


if [ -z "$(grep "redhat.xyz" /etc/nginx/nginx.conf)" ]; then
	echo "Initialize nginx"

	if [ "NGX_CACHE" = "Y" ]; then
		enable_cache=""
	else
		enable_cache="#"
	fi
	
	
	if [ "$NGX_USER" ]; then
		enable_status=""
		if [ "$PROXY_AUTH" = "Y" ]; then
			enable_auth=""
		else
			enable_auth="#"
		fi
	else
		enable_status="#"
		enable_auth="#"
	fi
	
	
	if [ "$(ls /key/ |egrep -c "server.crt|server.key")" -ne 2 ]; then
		openssl genrsa -out /etc/nginx/server.key 4096 2>/dev/null
		openssl req -new -key /etc/nginx/server.key -out /etc/nginx/server.csr -subj "/C=CN/ST=GuangDong/L=GuangZhou/O=JIOBXN Ltd/CN=NProxy-docker" 2>/dev/null
		openssl x509 -req -days 3650 -in /etc/nginx/server.csr -signkey /etc/nginx/server.key -out /etc/nginx/server.crt 2>/dev/null
	else
		\cp /key/{server.crt,server.key} /etc/nginx/
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

	charset utf-8;

	client_max_body_size 0;
	autoindex on;
	server_tokens off;

	$enable_cache    	proxy_cache cache1;
	proxy_cache_key \$scheme\$proxy_host\$request_uri\$cookie_user\$is_args\$args;
	$enable_cache    	proxy_cache_path /tmp/proxy_cache levels=1:2 keys_zone=cache1:$CACHE_TIME;
	proxy_cache_valid any      $CACHE_TIME;
	proxy_max_temp_file_size $MAX_CACHE;
	$enable_cache    	proxy_temp_path /tmp/proxy_temp 1 2 3;

	$enable_cache    	fastcgi_cache cache2;
	fastcgi_cache_key \$host\$request_uri;
	$enable_cache    	fastcgi_cache_path /tmp/fastcgi_cache levels=1:2 keys_zone=cache2:$CACHE_TIME;
	fastcgi_cache_valid any      $CACHE_TIME;
	fastcgi_max_temp_file_size $MAX_CACHE;
	$enable_cache    	fastcgi_temp_path /tmp/fastcgi_temp 1 2 3;

	gunzip on;
	gzip  on;
	gzip_comp_level 6;
	gzip_proxied any;
	gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/x-httpd-php image/jpeg image/gif image/png;
	gzip_vary on;

		include /etc/nginx/conf.d/*.conf;
	}
	daemon off;
	END

 
	#server
	cat >/etc/nginx/conf.d/default.conf <<-END
	server {
	    listen       $HTTP_PORT;
	    listen       $HTTPS_PORT ssl;
	    server_name *.$NGX_DOMAIN;

	    ssl_certificate      /etc/nginx/server.crt;
	    ssl_certificate_key  /etc/nginx/server.key;

	    ssl_session_cache shared:SSL:1m;
	    ssl_session_timeout  5m;

	    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
	    ssl_ciphers  HIGH:!aNULL:!MD5;
	    ssl_prefer_server_ciphers   on;
		
	    #rewrite#
	    #if (\$host !~* ^.*.$NGX_DOMAIN$) {return 301 https://cn.bing.com;}
	    if (\$uri = /\$host) {rewrite ^(.*)$ http://\$host/index.php;}    #t66y login jump

		
	    set \$domain $NGX_DOMAIN;
		
	    location / {
            resolver $NGX_DNS;
            #domains#
            #if (\$host ~* "^(.*).$NGX_DOMAIN$") {set \$domains \$1;}
            #if (\$host ~* "^(.*)-(.*).$NGX_DOMAIN$" ) {set \$domains \$1.\$2;}
            if (\$host ~* "^(.*)$TAG(.*).$NGX_DOMAIN$" ) {set \$domains \$1\$2;}     #host rule
            if (\$domains = "t66y.com" ) {charset gb2312;}                           #t66y charset
            
            proxy_pass http://\$domains;
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
            #sub_filter#
            sub_filter https:// http://;
            sub_filter .ytimg.com .yt${TAG}img.com.\$domain;
            sub_filter .googlevideo.com .goog${TAG}levideo.com.\$domain;
            sub_filter .ggpht.com .gg${TAG}pht.com.\$domain;
            sub_filter .twimg.com .tw${TAG}img.com.\$domain;
            sub_filter .fbcdn.net .fb${TAG}cdn.net.\$domain;
            sub_filter .tumblr.com .tu${TAG}mblr.com.\$domain;
            sub_filter \$proxy_host \$host;
			
	$enable_auth        auth_basic           "Nginx Auth";
	$enable_auth        auth_basic_user_file /etc/nginx/.htpasswd;

	    }
			
            error_page   500 502 503 504  /50x.html;
            location = /50x.html {return 301 https://cn.bing.com;}
            
	$enable_status    location ~ /basic_status {
	$enable_status        stub_status;
	$enable_status        auth_basic           "Nginx Stats";
	$enable_status        auth_basic_user_file /etc/nginx/.htpasswd;
	$enable_status    }
	}
	END
	
	
	
	if [ "$PROXY_HTTPS" = "Y" ]; then
		sed -i 's/proxy_pass http/proxy_pass https/g' /etc/nginx/conf.d/default.conf
	fi
	
	
	if [ "$NGX_FILTER" ]; then
		for i in $(echo $NGX_FILTER |sed 's/;/\n/g') ;do
			if [ $(echo $i |grep ",,") ]; then
				TEXT_A=$(echo $i |awk -F"," '{print $1}')
				TEXT_B=$(echo $i |awk -F"," '{print $2}')
				sed -i '/#sub_filter#/ a \            sub_filter '$TEXT_A' '$TEXT_B';' /etc/nginx/conf.d/default.conf
			else
				sed -i '/#sub_filter#/ a \            sub_filter '$i' $host;' /etc/nginx/conf.d/default.conf
			fi
		done
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
				-v /docker/nproxy:/key \\
				-p 80:80 \\
				-p 443:443 \\
				-e HTTP_PORT=[80] \\
				-e HTTPS_PORT=[443] \\
				-e TAG=["-"] \\
				-e NGX_DOMAIN=[example.com] \\
				-e PROXY_HTTPS=<Y> \\
				-e NGX_DNS=[8.8.8.8] \\
				-e PROXY_AUTH=<Y> \\
				-e NGX_USER=<admin> \\
				-e NGX_PASS=<redhat> \\
				-e NGX_CACHE=<Y> \\
				-e CACHE_TIME=[30m] \\
				-e MAX_CACHE=[1000m] \\
				-e NGX_FILTER=<text1,text2;text3> \\
				--hostname nproxy \\
				--name nproxy nproxy
	"	
fi
