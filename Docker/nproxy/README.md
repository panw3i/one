NProxy
===

> **NProxy**是一个nginx代理，可以代理访问任意网站

## Example:

    docker run -d --restart always -p 80:80 -p 443:443 -v /docker/nproxy:/key -e PROXY_HTTPS=Y -e NGX_DOMAIN=fqhub.com -e TAG=888 --hostname nproxy --name nproxy nproxy

    #访问google示例 http://www.goo888gle.com.hk.fqhub.com

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always \\
				-v /docker/nproxy:/key \\
				-p 80:80 \\
				-p 443:443 \\
				-e HTTP_PORT=[80] \\
				-e HTTPS_PORT=[443] \\
				-e TAG=["-"] \\                 默认分隔符
				-e NGX_DOMAIN=[example.com] \\  默认域名，将你的域名泛解析到服务器IP，或者修改hosts
				-e PROXY_HTTPS=<Y> \\           后端是否启用了https
				-e NGX_DNS=[8.8.8.8] \\         DNS
				-e PROXY_AUTH=<Y> \\            启用用户登陆访问
				-e NGX_USER=<admin> \\          用户名
				-e NGX_PASS=<redhat> \\         默认随机密码
				-e NGX_CACHE=<Y> \\             是否开启缓存
				-e CACHE_TIME=[30m] \\          缓存的时间
				-e MAX_CACHE=[1000m] \\         缓存的大小
				-e NGX_FILTER=<text1,text2;text3> \\    字符串替换，text2替换掉text1，如果只有一个text3就会被$host替换掉
				--hostname nproxy \\
				--name nproxy nproxy
