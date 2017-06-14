Shadowsocks
===

## Example:

    #运行一个SS服务器
    docker run -d --restart always -p 8443:8443 -e SS_PASS=MyPassw01d --hostname ss --name ss jiobxn/shadowsocks

    #运行一个SSR服务器
    docker run -d --restart always -p 8444:8443 -e SS_PASS=MyPassw01d -e SSR=Y --hostname ssr --name ssr jiobxn/shadowsocks

    #运行一个SS客户端
    docker run -d --restart always --network=host -e SS_ADDR=<server ip> -e SS_PORT=8443 -e SS_PASS=MyPassw01d -e SL_ADDR=0.0.0.0 --hostname ss --name ss jiobxn/shadowsocks

    #运行一个SSR客户端
    docker run -d --restart always --network=host -e SS_ADDR=<server ip> -e SS_PORT=8444 -e SS_PASS=MyPassw01d -e SSR=Y -e SL_ADDR=0.0.0.0 --hostname ssr --name ssr jiobxn/shadowsocks


****

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always \\
				-p 8443:8443 \
				-e SS_PASS=[newpass] \\        随机密码
				-e SS_EMOD=[aes-256-cfb] \\    加密方式
				-e SS_PORT=[8443] \\           服务器端口
				-e SS_OBFS=[tls1.2_ticket_auth_compatible] \\    混淆插件
				-e SS_PROTOCOL=[auth_aes128_sha1] \\             协议插件
				-e SSR=<Y> \\                启用SSR
				-e SS_ADDR=<SS_ADDR> \\      服务器地址
				-e SL_ADDR=[127.0.0.1] \\    本地监听地址
				-e SL_PORT=[1080] \\         本地监听端口
				--hostname shadowsocks --name shadowsocks shadowsocks

****

## 在终端中使用代理

使用代理(当前终端)

    export https_proxy=socks5://127.0.0.1:1080
    export http_proxy=socks5://127.0.0.1:1080

禁用代理

    unset http_proxy
    unset https_proxy

添加到环境变量(当前用户)

    echo -e "export https_proxy=socks5://127.0.0.1:1080\nexport http_proxy=socks5://127.0.0.1:1080" >>~/.bashrc
    source ~/.bashrc

为所有用户设置代理是在"/etc/bashrc"

验证

    curl -s https://showip.net/ ;echo

示例

    为http网站设置代理；export http_proxy=socks4://192.168.1.1:1080
    为https网站设置代理；export https_proxy=socks5://192.168.1.1:1080
    为ftp协议设置代理：export ftp_proxy=socks5://192.168.1.1:1080
    使用http代理+用户名密码认证：export http_proxy=user:pass@192.168.1.100:3128     #待验证
    使用https代理+用户名密码认证：export https_proxy=user:pass@192.168.1.100:3128   #待验证
    白名单：export no_proxy="*.aiezu.com,10.*.*.*,192.168.*.*,*.local,localhost,127.0.0.1"
    默认是sock4：export http_proxy=socks://192.168.1.1:1080

****

## 客户端下载
https://github.com/shadowsocks/shadowsocks/wiki/Ports-and-Clients  
https://github.com/breakwa11/shadowsocks-rss

### 协议插件文档
https://github.com/breakwa11/shadowsocks-rss/wiki/obfs  
https://github.com/breakwa11/shadowsocks-rss/blob/master/ssr.md  
https://github.com/breakwa11/shadowsocks-rss/wiki/config.json
