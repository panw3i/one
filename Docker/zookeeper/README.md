ZooKeeprt
===

## Example:

    #运行一个单机版ZK
    docker run -d --restart always -p 2181:2181 -v /docker/zookeeper:/var/lib/zookeeper --hostname zookeeper --name zookeeper zookeeper

    #运行一个ZK集群
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.71 -v /docker/zookeeper1:/var/lib/zookeeper -e ZK_SERVER=10.0.0.71,10.0.0.72,10.0.0.73 -e VIP=10.0.0.70 --hostname zookeeper1 --name zookeeper1 zookeeper
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.72 -v /docker/zookeeper2:/var/lib/zookeeper -e ZK_SERVER=10.0.0.71,10.0.0.72,10.0.0.73 -e VIP=10.0.0.70 --hostname zookeeper2 --name zookeeper2 zookeeper
    docker run -d --restart always --privileged --network=mynetwork --ip=10.0.0.73 -v /docker/zookeeper3:/var/lib/zookeeper -e ZK_SERVER=10.0.0.71,10.0.0.72,10.0.0.73 -e VIP=10.0.0.70 --hostname zookeeper3 --name zookeeper3 zookeeper

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always [--privileged] \\
				-v /docker/zookeeper:/var/lib/zookeeper \\
				-p 2181:2181 \\
				-e ZK_MEM=[2048m] \\                                  默认为物理内存的%70
				-e ZK_SERVER=<"10.0.0.71,10.0.0.72,10.0.0.73"> \\     集群节点数建议大于或等于3
				-e VIP=<10.0.0.70> \\                                 leader IP Addr，需要 --privileged
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\        防火墙(2181)，需要 --privileged
				--hostname zookeeper \\
				--name zookeeper zookeeper
