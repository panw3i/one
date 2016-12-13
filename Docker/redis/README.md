Redis
===

    在国内的网络环境Build很容易失败，在Dockerfile开启更换Gem源

## Example:

    docker run -d --restart always --privileged -v /docker/redis:/usr/local/redis/data -p 16379:6379  -e REDIS_PASS=bigpass --hostname redis --name redis redis

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart always --privileged \\
					-v /docker/redis:/usr/local/redis/data \\
					-p 16379:6379 \\
					-e REDIS_PASS=<bigpass> \\  redis密码
					-e REDIS_PORT=[6379] \\     端口
					-e LOCAL_STROGE=Y \\        开启持久化
					--hostname redis \\
					--name redis redis

