Shadowsocks
===

## Example:

    docker run -d --restart always -p 8443:8443 -e SS_PASS=MyPassw01d --hostname shadowsocks --name shadowsocks jiobxn/shadowsocks

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

			docker run -d --restart always \\
				-p 8443:8443 \
				-e SS_PASS=[pwmake 64] \\      随机密码
				-e SS_EMOD=[aes-256-cfb] \\    加密方法
				-e SS_PORT=[8443] \\           服务端口
				--hostname shadowsocks --name shadowsocks shadowsocks
