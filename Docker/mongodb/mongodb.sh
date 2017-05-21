#!/bin/bash
set -e

: ${MONGO_ID:="rs0"}

if [ "$1" = 'mongod' ]; then
	##USER
	mongo_user() {
	#Create root
	if [ -n "$MONGO_ROOT_PASS" ]; then
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

		mongo <admin.json &>/dev/null
		echo "MongoDB ROOT PASSWORD: $MONGO_ROOT_PASS" |tee /var/lib/mongo/root_info
		AUTH="-u root -p $MONGO_ROOT_PASS --authenticationDatabase admin"
	fi

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
	}


	##BASE
	mongo_base() {
	mongod -f /etc/mongod.conf
	sed -i 's/#security:/security:/' /etc/mongod.conf
	sed -i '/security:/ a \  authorization: enabled' /etc/mongod.conf
	sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
	sed -i 's/fork: true/#fork: true/' /etc/mongod.conf
	[ "$MONGO_HTTP" ] && sed -i '/net:/ a \  http:\n \    enabled: true' /etc/mongod.conf
	mongo_user
	/usr/local/bin/mongod -f /etc/mongod.conf --shutdown &>/dev/null
	}


	##Clustered
	mongo_gluster() {
	if [ "$VIP" ]; then
		sed -i 's/#replication:/replication:/' /etc/mongod.conf
		sed -i '/replication:/ a \  replSetName: '$MONGO_ID'' /etc/mongod.conf
		sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
		[ "$MONGO_HTTP" ] && sed -i '/net:/ a \  http:\n \    enabled: true' /etc/mongod.conf
		[ "$MONGO_SERVER" ] && /usr/local/bin/mongod -f /etc/mongod.conf &>/dev/null
		sed -i 's/fork: true/#fork: true/' /etc/mongod.conf

		cat >/vip.sh<<-END
		#!/bin/bash
		PASS="$AUTH"
		if [ ! -f "/var/lib/mongo/myid" ]; then
		for i in \$(echo 'rs.status()' |/usr/local/bin/mongo $PASS |grep '"name"' |awk -F\" '{print \$4}' |awk -F: '{print \$1}'); do
			for ip in \$(ifconfig |grep netmask |awk '{print \$2}'); do
				[ "\$ip" == "\$i" ] && echo \$ip >/var/lib/mongo/myid
			done
		done
		fi

		for i in {1..29}; do
		if [ "\$(echo 'rs.status()' |/usr/local/bin/mongo $PASS |grep -A 3 "\"name\" : \"\$(cat /var/lib/mongo/myid):27017\"" |awk -F\" 'END{print \$4}')" == "PRIMARY" ]; then
		    if [ -z "\$(ifconfig |grep $VIP)" ]; then
		        ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up || echo
		    fi
		    sleep 2
		else
		    if [ -n "\$(ifconfig |grep $VIP)" ]; then
		        ifconfig lo:0 del $VIP || echo
		    fi
		    sleep 2
		fi
		done
		END
		chmod +x /vip.sh
		echo "* * * * * . /etc/profile;/bin/sh /vip.sh &>/dev/null" >>/var/spool/cron/root
	fi
	
	
	if [ $MONGO_SERVER ]; then
		sleep 2
		for i in $(echo $MONGO_SERVER |sed 's/,/\n/g'); do
		if [ -n "$(ifconfig |grep $i)" ]; then
			cat >replset.json<<-END
			rs.initiate( {
				_id : "$MONGO_ID",
				members: [ { _id : 0, host : "$i:27017" } ]
			})
			END
			mongo < replset.json 1>/dev/null
		fi
		done
		for i in $(echo $MONGO_SERVER |sed 's/,/\n/g'); do
		[ -z "$(ifconfig |grep $i)" ] && echo "rs.add(\"$i\")" |mongo 1>/dev/null
		done
		mongo_user
		exec "/usr/sbin/init"
	fi
	}


	mongo_other() {
	#Backup Database
	if [ "$MONGO_BACK" ]; then
		[ -z "$MONGO_ROOT_PASS" ] && MONGO_ROOT_PASS=$(awk '{print $4}' /var/lib/mongo/root_info)
		sed -i 's/newpass/'$AUTH'/' /backup.sh
		echo "0 4 * * * . /etc/profile;/bin/sh /backup.sh &>/dev/null" >>/var/spool/cron/root
	fi

	#iptables, Need root authority "--privileged"
	if [ $IPTABLES ]; then
		cat > /iptables.sh <<-END
		iptables -I INPUT -p tcp -m multiport --dport 27017,28017 -j DROP
		iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -I INPUT -s 127.0.0.1 -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 27017 -m comment --comment MONGDB -j ACCEPT
		iptables -I INPUT -s $IPTABLES -p tcp -m state --state NEW -m tcp --dport 28017 -m comment --comment MONGDB -j ACCEPT
		END
	fi
	
	[ -f /iptables.sh ] && [ -z "`iptables -S |grep MONGDB`" ] && . /iptables.sh || echo
	crond
	}


	##start
	if [ -d "/var/lib/mongo/diagnostic.data" ]; then
		echo "/var/lib/mongo/diagnostic.data already exists, skip"
		mongo_other
	else
		echo "Initializing MongoDB"
		if [ "$VIP" ]; then
			mongo_other
			mongo_gluster
		else
			mongo_base
			mongo_other
		fi
	fi


	echo "Start MongoDB ****"
	exec "$@" 1>/dev/null

else

    echo -e "
    Example:
				docker run -d --restart always [--privileged] \\
				-v /docker/mongodb:/var/lib/mongo \\
				-p 27017:27017 \\
				-p 28017:28017 \\
				-e MONGO_ROOT_PASS=<newpass> \\
				-e MONGO_USER=<user1> \\
				-e MONGO_PASS=<newpass> \\
				-e MONGO_DB=<test> \\
				-e MONGO_HTTP=<Y> \\
				-e MONGO_BACK=<Y> \\
				-e MONGO_ID=[rs0] \\
				-e VIP=<10.0.0.80>
				-e MONGO_SERVER=<10.0.0.81,10.0.0.82,10.0.0.83>
				-e IPTABLES=<"192.168.10.0/24,10.0.0.0/24"> \\
				--hostname mongodb \\
				--name mongodb mongodb
	"
fi
