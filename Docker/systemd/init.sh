#!/bin/bash
set -e

xtrabackup() {
	[ -z "$MYSQL_ROOT_PASSWORD" ] && MYSQL_ROOT_PASSWORD=$(awk '{print $4}' /var/lib/mysql/root_info 2>/dev/null)

	cat >>/xtrabackup.sh <<-END
	xtrabackup --user=root --password=$MYSQL_ROOT_PASSWORD --backup --target-dir=/xtrabackup 2>/xtrabackup.log
	xtrabackup --prepare --target-dir=/xtrabackup 2>>/xtrabackup.log
	cp /var/lib/mysql/*_info /xtrabackup/
	chown -R 27:27 /xtrabackup
	grep "completed OK" /xtrabackup.log >/root/xtrabackup.log
	END
	atd
	echo "sh /xtrabackup.sh" |at now +1 minutes
}


if [ "$1" = "/usr/sbin/init" ]; then
	exec "$@"
elif [ "$1" = "xtrabackup" ]; then
	xtrabackup
else
	echo "Example:"
	echo "docker run -d --restart always --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name systemd systemd"
	echo
	echo
	echo -e "MySQL repl: MySQL Master and Slave root passwords to be consistent."
	echo "1."
	echo "docker run -d --restart always --privileged --ip=192.168.10.131 --net=mynetwork -v /docker/mysql-mini:/var/lib/mysql -v /docker/sql:/docker-entrypoint-initdb.d -e MYSQL_ROOT_PASSWORD=newpass -e MYSQL_BACK=Y -e SERVER_ID=1 -e REPL_IPR=192.168.10.% -e REPL_USER=repl -e REPL_PASSWORD=newpass --hostname mysql --name mysql mysql-mini"
	echo "2."
	echo "docker run -d --restart always --privileged -v /docker/mysql-mini:/var/lib/mysql -v /docker/mysql-mini2:/xtrabackup -e MYSQL_ROOT_PASSWORD=newpass --name xtrabackup systemd xtrabackup"
	echo "3."
	echo "docker run -d --restart always --privileged --ip=192.168.10.132 --net=mynetwork -v /docker/mysql-mini2:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=newpass -e MYSQL_BACK=Y -e SERVER_ID=2 -e MASTER_HOST=192.168.10.131 -e REPL_USER=repl -e REPL_PASSWORD=newpass --hostname mysql2 --name mysql2 mysql-mini"
fi

exec "/usr/sbin/init"
