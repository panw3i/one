Kafka
===

## Example:

    #运行一个单机版Kafka
    docker run -d --restart always --network=mynetwork --ip=10.0.0.100 -p 9092:9092 -v /docker/kafka:/var/lib/kafka-logs -e ZK_SERVER=10.0.0.70:2181 -e KK_TOPIC=test:1:1 --hostname kafka --name kafka kafka
    
    #运行一个Kafka集群
    docker run -d --restart always --network=mynetwork --ip=10.0.0.101 -v /docker/kafka1:/var/lib/kafka-logs -e ZK_SERVER=10.0.0.70:2181 -e KK_ID=0 --hostname kafka1 --name kafka1 kafka
    docker run -d --restart always --network=mynetwork --ip=10.0.0.102 -v /docker/kafka2:/var/lib/kafka-logs -e ZK_SERVER=10.0.0.70:2181 -e KK_ID=1 --hostname kafka2 --name kafka2 kafka
    docker run -d --restart always --network=mynetwork --ip=10.0.0.103 -v /docker/kafka3:/var/lib/kafka-logs -e ZK_SERVER=10.0.0.70:2181 -e KK_ID=2 -e KK_TOPIC=test1:3:1,test2:3:3 --hostname kafka3 --name kafka3 kafka

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always [--privileged] \\
				-v /docker/kafka:/var/lib/kafka-logs \\
				-p 9092:9092 \\
				-e KK_MEM=[1G] \\                                  默认内存大小1G
				-e KK_NET=[3] \\                                   默认网络线程3个
				-e KK_IO=[8] \\                                    默认存储线程8个
				-e KK_TIME=[168]                                   默认日志储存时间7天
				-e KK_SERVER=[ethX ip]                             默认取网关接口IP地址
				-e KK_ID=[0] \\                                    默认ID是0，在一个集群环境每个节点的ID不能相同
				-e KK_TOPIC=<test:1:1> \\                          创建一个topic，格式“topic:replication-factor:partitions"，要创建多个用逗号","分隔
				-e ZK_SERVER=<"10.0.0.70:2181"> \\                 指定zookeeper地址和端口，要使用多台用逗号","分隔
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\     防火墙(9092)，需要 --privileged
				--hostname kafka \\
				--name kafka kafka

## 补充
查看集群状态：

    kafka-topics.sh --describe --zookeeper 10.0.0.70:2181 --topic test1

Kafka一些概念：

    topic：一个话题，相当于一个漏斗名称
    replication-factor：topic副本数。例如一个3节点集群，test1:3:1，就表示test1在3个节点上有副本，每个副本存储在1一个分区(文件夹)
    partitions：分区数。例如一个3节点集群，test1:3:4，就表示test1在3个节点上有副本，每个副本存储在4个分区(文件夹)

