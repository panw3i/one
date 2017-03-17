Nginx
===

## Example:

    #运行一个PHP环境的nginx实例
    docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/www:/usr/local/nginx/html -e PHP_SERVER=172.17.0.8:9000 --hostname nginx --name nginx nginx

    #运行一个tomcat环境的nginx实例
    docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/webapps:/usr/local/nginx/html -e TOMCAT_SERVER=172.17.0.10:18080 --hostname nginx --name nginx nginx

    #运行一个反向代理的nginx实例
    docker run -d --restart always -p 10080:80 -p 10443:443 -e PROXY_SERVER=172.17.0.13 --hostname nginx --name nginx nginx
    docker run -d --restart always -p 80:80 -p 443:443 -e PROXY_SERVER="jiobxn.com,www.jiobxn.com|jiobxn.wordpress.com" -e PROXY_HTTPS=Y --hostname nginx --name nginx nginx

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always \\
				-v /docker/www:/usr/local/nginx/html \\
				-v /docker/upload:/upload \\  alias目录，在集群环境中通常挂载到分布式存储用于存储图片
				-v /docker/key:/key \\  ssl证书{server.crt,server.kry}
				-p 10080:80 \\
				-p 10443:443 \\
				-e HTTP_PORT=[80] \\    HTTP端口
				-e HTTPS_PORT=[443] \\  HTTPS端口
				-e NGX_CODING=[utf-8] \\   默认字符集
				-e PHP_SERVER=<'php.redhat.xyz,www.redhat.xyz|10.0.0.11:9000,10.0.0.12:9000'> \\  PHP服务器地址，"|"前面是主机名，后面是PHP服务器地址
				-e PHP_PATH=[/var/www] \\  PHP工作路径
				-e JAVA_SERVER=<'java.redhat.xyz,redhat.xyz|10.0.0.21:1080,10.0.0.22:2080'> \\    tomcat服务器地址，"|"前面是主机名，后面是PHP服务器地址
				-e TOMCAT_HTTPS=<Y> \\     后端tomcat启用了https
				-e PROXY_SERVER=<'a.redhat.xyz|10.0.0.31,10.0.0.41;b.redhat.xyz|www.baidu.com'> \\  反向代理，以";"分割为一组
				-e PROXY_HTTPS=<Y> \\      代理的后端服务器启用了https
				-e PROXY_HEADER=<2|host;http_host> \\  反向代理的主机头，默认是proxy_host
				-e FULL_HTTPS=<Y> \\       开启全站https
				-e DEFAULT_SERVER=<redhat.xyz> \\  默认主机名，如果有多个主机名，指定默认的
				-e IP_HASH=<Y> \\          开启IP HASH
				-e PHP_ALIAS=<'/upload,/upload'> \\    alisa，第一个upload是别名，第二个upload是目录路径
				-e JAVA_ALIAS=<'/upload,/upload'> \\
				-e NGX_USER=<admin> \\    用于查看/basic_status的用户
				-e NGX_PASS=<redhat> \\   默认随机密码
				--hostname nginx \\
				--name nginx nginx
