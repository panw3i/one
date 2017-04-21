Percona Xtradb Cluster
===

## Example:

    #运行一个MySQL 5.7集群（集群的最少节点数，建议为3）
    docker run -d --restart always --network=mynetwork --ip=10.0.0.61 -v /docker/pxc1:/var/lib/mysql -e REPL_IPR=10.0.0.% -e MYSQL_ROOT_PASSWORD=newpass -e PXC_ADDRESS="10.0.0.61,10.0.0.62,10.0.0.63" -e XPC_INIT=Y --hostname pxc1 --name pxc1 mysql-pxc:5.7
    docker run -d --restart always --network=mynetwork --ip=10.0.0.62 -v /docker/pxc2:/var/lib/mysql -e PXC_ADDRESS="10.0.0.61,10.0.0.62,10.0.0.63" --hostname pxc2 --name pxc2 mysql-pxc:5.7
    docker run -d --restart always --network=mynetwork --ip=10.0.0.63 -v /docker/pxc3:/var/lib/mysql -e PXC_ADDRESS="10.0.0.61,10.0.0.62,10.0.0.63" --hostname pxc3 --name pxc3 mysql-pxc:5.7

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always [--privileged] \\
				-v /docker/pxc1:/var/lib/mysql \\                      数据持久化
				-v /docker/sql:/docker-entrypoint-initdb.d \\          要导入的数据库放这里
				-e XPC_INIT=<Y> \\                                     初始化集群，在一个集群环境中必须要一台开启初始化
				-e PXC_ADDRESS=<"10.0.0.61,10.0.0.62,10.0.0.63"> \\    集群地址，逗号分隔
				-e MYSQL_ROOT_PASSWORD=<newpass> \\                     MySQL远程root密码
				-e MYSQL_ROOT_LOCAL_PASSWORD=[newpass] \\               MySQL本地root密码，用于密码冗余
				-e MYSQL_SSTUSER_PASSWORD=[passw0rd] \\                 sstuser密码，用于集群数据传输
				-e MYSQL_REPL_PASSWORD=[123456] \\                      repl密码，用于添加外部slave节点的复制
				-e REPL_IPR=<"10.0.0.%"> \\                             外部slave节点的IP段
				-e LOG_BIN=<Y> \\                                       开启集群节点的master功能
				-e SYNC_BINLOG=[0] \\                                   二进制日志写入磁盘的模式，0 每秒写入、1 每次事物写入
				-e MYSQL_DATABASE=<zabbix> \\                           初始化集群时创建一个数据库
				-e MYSQL_USER=<zabbix> \\                               初始化集群时创建一个用户
				-e MYSQL_PASSWORD=<zbxpass> \\                          初始化集群时创建用户的密码
				-e MYSQL_MAX_CONN=[800] \\                             最大连接数
				--hostname mysql-pxc \\
				--name mysql-pxc mysql-pxc
