#!/bin/bash
set -e

if [ "$1" = '/usr/sbin/sshd' ]; then

: ${REDIS_PORT:=16379}
: ${DB_PORT:=13306}
: ${DB_USER:=git}
: ${DB_PASS:=Newp@555}
: ${DB_NAME:=gitlabhq_production}
: ${SSH_PORT:=2222}
: ${HTTP_PORT:=8888}
: ${SMTP_HOST:=smtp.exmail.qq.com}


#initialize key
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	mkdir -p /var/run/sshd
	ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
fi

#initialize gitlab
if [ ! -f /etc/init.d/gitlab ]; then
	# Get ip address
	DEV=$(route -n |awk '$1=="0.0.0.0"{print $NF }')
	if [ -z $HTTP_SERVER ]; then
		HTTP_SERVER=$(curl -s https://httpbin.org/ip |awk -F\" 'NR==2{print $4}')
	fi

	if [ -z $HTTP_SERVER ]; then
		HTTP_SERVER=$(curl -s https://showip.net/)
	fi

	if [ -z $HTTP_SERVER ]; then
		HTTP_SERVER=$(ifconfig $DEV |awk '$3=="netmask"{print $2}')
	fi


	chown git.git /home/git/repositories

	#redis
	if [ $REDIS_SERVER ]; then
		sed -i 's@unix:/var/run/redis/redis.sock@redis://'$REDIS_SERVER':'$REDIS_PORT'@' /home/git/gitlab/config/resque.yml
	else
		echo -e "error. Not specified Redis server."
	fi
	
	
	#mysql
	if [ "$DB_SERVER" ]; then
		#Check databases
		DB=$(MYSQL_PWD="$DB_PASS" mysql -h$DB_SERVER -P$DB_PORT -u$DB_USER -e "USE $DB_NAME; SELECT 68;" |awk 'NR!=1{print $1,$2}')
		TAB=$(MYSQL_PWD="$DB_PASS" mysql -h$DB_SERVER -P$DB_PORT -u$DB_USER -e "USE $DB_NAME; SHOW TABLES;" |awk 'NR!=1{print $1,$2}' |wc -l)

		if [ "$DB" -eq 68 ]; then
			echo "Set database config"
			sed -i 's/secure password/'$DB_PASS'/' /home/git/gitlab/config/database.yml
			sed -i 's/# host: localhost/host: '$DB_SERVER'/' /home/git/gitlab/config/database.yml
			sed -i '/  host/ a \  port: '$DB_PORT'' /home/git/gitlab/config/database.yml
			sudo -u git -H chmod o-rwx /home/git/gitlab/config/database.yml

			if [ "$TAB" -gt 60 ]; then
				echo "Database table already exists, skip"
				sudo -u git -H \cp /home/git/repositories/secrets.yml /home/git/gitlab/config/
			else
				cd /home/git/gitlab
				expect -c "
				set timeout 600
				spawn sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production
				expect {
        		        \"*yes/no*\" {send \"yes\r\"; exp_continue}
				}
				"
				sudo -u git -H \cp /home/git/gitlab/config/secrets.yml /home/git/repositories/
			fi
		else
			echo "Database gitlabhq_production Write Failed"
			exit 1
		fi
	else
		echo -e "error. Not specified MySQL server."
		exit 1
	fi
	
	#other settings
	sudo cp /home/git/gitlab/lib/support/init.d/gitlab /etc/init.d/gitlab
	sudo cp /home/git/gitlab/lib/support/logrotate/gitlab /etc/logrotate.d/gitlab
#	sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production 2>/dev/null
	sed -i 's/127.0.0.1/0.0.0.0/' /home/git/gitlab/config/unicorn.rb
	sed -i 's/worker_processes 3/worker_processes '$(nproc)'/' /home/git/gitlab/config/unicorn.rb


	#Set the HTTP Server and Port
	sed -i 's/host: localhost/host: '$HTTP_SERVER'/' /home/git/gitlab/config/gitlab.yml
	if [ $HTTP_PORT -ne 80 -a $HTTP_PORT -ne 443 ]; then
		sed -i 's/port: 80/port: '$HTTP_PORT'/' /home/git/gitlab/config/gitlab.yml
		sed -i 's/localhost/'$HTTP_SERVER:$HTTP_PORT'/' /home/git/gitlab-shell/config.yml
	fi
	
	if [ $HTTPS ]; then
		sed -i 's/https: false/https: true/' /home/git/gitlab/config/gitlab.yml
		sed -i 's/self_signed_cert: false/self_signed_cert: true' /home/git/gitlab-shell/config.yml
	fi
	
	if [ $SSH_PORT ]; then
		sed -i 's/# ssh_port: 22/ssh_port: '$SSH_PORT'/' /home/git/gitlab/config/gitlab.yml
	fi

	#SMTP
	if [ $SMTP_USER ]; then
		if [ -z "$(echo $SMTP_USER |grep "^[a-zA-Z0-9_-]*@[A-Za-z_-]*\.[a-zA-Z_-]*$")" ]; then
			echo "ERROR.. Email is invalid"
			exit 1
		fi

		if [ $SMTP_PASS ]; then
			sed -i 's/:sendmail/:smtp/' /home/git/gitlab/config/environments/production.rb
			sed -i 's/example@example.com/'$SMTP_USER'/' /home/git/gitlab/config/gitlab.yml
			cp /home/git/gitlab/config/initializers/smtp_settings.rb.sample /home/git/gitlab/config/initializers/smtp_settings.rb
			sed -i 's/email.server.com/'$SMTP_HOST'/' /home/git/gitlab/config/initializers/smtp_settings.rb
			sed -i 's/465/25/' /home/git/gitlab/config/initializers/smtp_settings.rb
			sed -i 's/"smtp"/"'$SMTP_USER'"/' /home/git/gitlab/config/initializers/smtp_settings.rb
			sed -i 's/123456/'$SMTP_PASS'/' /home/git/gitlab/config/initializers/smtp_settings.rb
			sed -i 's/gitlab.company.com/'$SMTP_HOST'/' /home/git/gitlab/config/initializers/smtp_settings.rb
			sed -i 's/true/false/' /home/git/gitlab/config/initializers/smtp_settings.rb
		else
			echo "ERROR.. Password is null"
			exit 1
		fi
	fi


fi

	echo "Start ****"
	/usr/sbin/postfix start
	sudo -u git -H /etc/init.d/gitlab start

	exec "$@"
	#strace -f -p $(netstat -tupnl |grep unicorn_rails |awk '{print $NF}' |awk -F/ '{print $1}')

else

	echo -e "
	Example:
			docker run -d --restart always --privileged \\
			-p 2222:22 \\
			-p 8888:8080 \\
			-v /docker/gitlab:/home/git/repositories \\
			-e HTTP_SERVER=[SERVER_IP] \\
			-e HTTP_PORT=[8888] \\
			-e HTTPS=<Y> \\
			-e SSH_PORT=[2222] \\
			-e REDIS_SERVER=<redhat.xyz> \\
			-e REDIS_PORT=[16379] \\
			-e DB_SERVER=<redhat.xyz> \\
			-e DB_PORT=[13306] \\
			-e DB_USER=[git] \\
			-e DB_PASS=[Newp@555] \\
			-e DB_NAME=[gitlabhq_production] \\
			-e SMTP_HOST=[smtp.exmail.qq.com] \\
			-e SMTP_USER=<gitlab@example.com> \\
			-e SMTP_PASS=<password> \\
			--hostname gitlab --name \\
			gitlab gitlab
	"
fi