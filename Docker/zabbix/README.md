Zabbix
===

## Example:

    docker run -d --restart always --privileged -p 11080:80 -p 11443:443 -v /docker/www:/var/www/html -e PHP_SERVER=redhat.xyz -e ZBX_DB_SERVER=redhat.xyz -e ZBX_DB_PORT=13306 --hostname zabbix --name zabbix zabbix-httpd

    #访问zabbix示例 http://redhat.xyz:11080/zabbix   用户名/密码：admin/zabbix

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d --restart always --privileged \\
				-v /docker/www:/var/www/html \\
				-p 11080:80 \\
				-p 11443:443 \\
				-e PHP_SERVER=<redhat.xyz> \\    PHP服务器地址
				-e PHP_PORT=[9000] \\            PHP服务端口
				-e PHP_PATH=[/var/www] \\        PHP工作路径
				-e ZBX_DB_SERVER=<redhat.xyz> \\    mysql服务器地址
				-e ZBX_DB_PORT=[13306] \\           mysql服务端口
				-e ZBX_DB_USER=[zabbix] \\          mysql用户名
				-e ZBX_DB_PASSWORD=[newpass] \\     mysql密码
				-e ZBX_DB_DATABASE=[zabbix] \\      数据库名称
				--hostname zabbix-httpd \\
				--name zabbix-httpd zabbix-httpd

提示：zabbix默认使用 被动模式，即 server --> agent，agent要开放10050端口 。主动模式是 agent --> server 。
