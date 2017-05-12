MongoDB
===

## Example:

    docker run -d --restart always -p 27017:27017 -p 28017:28017 -v /docker/mongodb:/var/lib/mongo -e MONGO_ROOT_PASS=NewP@ss --hostname mongodb --name mongodb mongodb

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always \\
				-v /docker/mongodb:/var/lib/mongo \\
				-p 27017:27017 \\
				-p 28017:28017 \\
				-e MONGO_ROOT_PASS=[newpass] \\    默认用户 root 密码 newpass
				-e MONGO_USER=<user1> \\           创建一个mongodb用户
				-e MONGO_PASS=<newpass> \\         mongodb用户的密码
				-e MONGO_DB=<test> \\              创建的数据库名称，为空则与用户同名
				-e MONGO_HTTP=<Y> \\               开启HTTP功能
				-e MONGO_BACK=<Y> \\               开启自动备份数据库，默认只保留3天的备份
				--hostname mongodb \\
				--name mongodb mongodb
