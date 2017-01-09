Shadowsocks
===

## Example:

    docker run -d --restart always -p 8443:8443 --hostname shadowsocks --name shadowsocks jiobxn/shadowsocks

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

    SS_PASS=<passwd>       随机密码
    SS_EMOD=[aes-256-cfb]  加密方式
    SS_PORT=[8443]         端口
