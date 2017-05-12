#!/bin/bash
set -e

: ${MONGO_ROOT_PASS:="newpass"}

if [ "$1" = 'mongod' ]; then
	if [ -d "/var/lib/mongo/diagnostic.data" ]; then
		echo "/var/lib/mongo/diagnostic.data already exists, skip"
	else
		#Access control
		echo "Initializing MongoDB $(mongod --version |awk 'NR==1{print $NF}')"
		mongod -f /etc/mongod.conf

		cat >admin.json<<-END
		use admin
		db.createUser(
		  {
			user: "root",
			pwd: "$MONGO_ROOT_PASS",
			roles: [ { role: "userAdminAnyDatabase", db: "admin" },
			         { role: "backup", db: "admin" },
			         { role: "restore", db: "admin" } ]
		  }
		)
		END

		sed -i 's/#security:/security:/' /etc/mongod.conf
		sed -i '/security:/ a \  authorization: enabled' /etc/mongod.conf
		mongo <admin.json &>/dev/null
		echo
		echo "MongoDB ROOT PASSWORD: $MONGO_ROOT_PASS" |tee /var/lib/mongo/root_info

		#Create a database and database user
		if [ -n "$MONGO_USER" -a -n "$MONGO_PASS" ]; then
			[ -z "$MONGO_DB" ] && MONGO_DB=$MONGO_USER
			
			cat >user.json<<-END
			use $MONGO_DB
			db.createUser(
			  {
			    user: "$MONGO_USER",
			    pwd: "$MONGO_PASS",
			    roles: [ { role: "dbOwner", db: "$MONGO_DB" } ]
			  }
			)
			END

			mongo <user.json &>/dev/null
			echo "MongoDB USER AND PASSWORD: $MONGO_USER  $MONGO_PASS" |tee /var/lib/mongo/user_info
		fi

		mongod -f /etc/mongod.conf --shutdown &>/dev/null
	fi

	#Backup Database
	if [ "$MONGO_BACK" ]; then
		[ -z "$MONGO_ROOT_PASS" ] && MONGO_ROOT_PASS=$(awk '{print $4}' /var/lib/mongo/root_info)
		sed -i 's/newpass/'$MONGO_ROOT_PASS'/' /backup.sh
		echo "0 4 * * * . /etc/profile;/bin/sh /backup.sh >/dev/null  2>&1" >>/var/spool/cron/root
	fi
		
	sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
	sed -i 's/fork: true/#fork: true/' /etc/mongod.conf
	[ "$MONGO_HTTP" ] && sed -i '/net:/ a \  http:\n \    enabled: true' /etc/mongod.conf

	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp --dport $MYSQL_PORT -j DROP
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 27017,28017 -j ACCEPT
		END
	fi
	
	echo "Start MongoDB ****"
	#[ -f /iptables.sh ] && . /iptables.sh
	crond

	exec "$@" &>/dev/null
else

    echo -e "
    Example:
				docker run -d --restart always [--privileged] \\
				-v /docker/mongodb:/var/lib/mongo \\
				-p 27017:27017 \\
				-p 28017:28017 \\
				-e MONGO_ROOT_PASS=[newpass] \\
				-e MONGO_USER=<user1> \\
				-e MONGO_PASS=<newpass> \\
				-e MONGO_DB=<test> \\
				-e MONGO_HTTP=<Y> \\
				-e MONGO_BACK=<Y> \\
				--hostname mongodb \\
				--name mongodb mongodb
	"
fi
