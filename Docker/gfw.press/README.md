GFW.Press
===
新一代军用级高强度加密抗干扰网络数据高速传输软件

## Example:

    docker run -d --restart always --privileged --network=host -v /docker/gfw.press:/key --hostname gfw.press --name gfw.press gfw.press
    docker logs gfw.press

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always --privileged \\
				--network=host \\
				-v /docker/gfw.press:/key \\
				-p 8080:10005 \\                       如果你不想使用 --privileged --network=host ，那就用用端口映射
				-e GFW_PORT=[10001..10005] \\          默认开启5个端口，例如想要100个端口: GFW_PORT=10001..10100
				-e GFW_PASS=[newpass|N] \\             默认是使用相同的随机密码，可自定义密码，不要太简单，如果想每个端口的密码不一样: GFW_PASS=N
				-e GFW_EMOD=[squid|sockd] \\           默认使用squid，如果想使用socks5: GFW_EMOD=sockd
				--hostname gfw.press \\
				--name gfw.press gfw.press

## 客户端下载 https://github.com/chinashiyu/gfw.press
