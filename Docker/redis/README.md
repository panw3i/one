Redis
===

    在国内的网络环境Build很容易失败，在Dockerfile开启更换Gem源

## Example:

    #运行一个单机版redis
    docker run -d --restart always --privileged -v /docker/redis:/usr/local/redis/data -p 6379:6379 -e LOCAL_STROGE=Y -e REDIS_PASS=bigpass --hostname redis --name redis redis

    #运行一个redis主从
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.91 -v /docker/redis1:/usr/local/redis/data -e LOCAL_STROGE=Y -e REDIS_PASS=bigpass -e VIP=10.0.0.90 --hostname redis --name redis redis
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.92 -v /docker/redis2:/usr/local/redis/data -e LOCAL_STROGE=Y -e REDIS_PASS=bigpass -e REDIS_MASTER=10.0.0.91 -e VIP=10.0.0.90 -e MASTER_PASS=bigpass --hostname redis --name redis redis

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

					docker run -d --restart always --privileged \\
					-v /docker/redis:/usr/local/redis/data \\
					-p 16379:6379 \\
					-e REDIS_PASS=<bigpass> \\            设置一个密码
					-e LOCAL_STROGE=Y \\                  开启持久化
					-e REDIS_MASTER=<10.0.0.91> \\        master ip addr
					-e MASTER_PASS=<bigpass> \\           master密码
					-e VIP=<10.0.0.90> \\                 master ip addr
					-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\    防火墙，需要 --privileged
					--hostname redis \\
					--name redis redis

