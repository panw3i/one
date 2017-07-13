#!/bin/bash
set -e

if [ "$1" = 'httpd' ]; then

: ${REPOS:=repos}
: ${ADMIN:=admin}
: ${USER:=user1}
: ${ADMIN_PASS:=passwd0}
: ${USER_PASS:=passwd1}

if [ -z "$(grep "redhat.xyz" /etc/httpd/conf/httpd.conf)" ]; then
	echo "Initialize httpd"
	#key
	if [ -f /key/server.crt -a -f /key/server.key ]; then
		\cp /key/server.crt /etc/pki/tls/certs/localhost.crt
		\cp /key/server.key /etc/pki/tls/private/localhost.key
	fi
	
	#httpd
	cat >>/etc/httpd/conf/httpd.conf <<-END
	#
	#redhat.xyz
	ServerName localhost
	AddDefaultCharset UTF-8

	<IfModule deflate_module>  
	AddOutputFilterByType DEFLATE all  
	SetOutputFilter DEFLATE  
	</ifModule>  

	#svn
	<Location /svn>
	  DAV svn
	  SVNParentPath /home/svn
	  SVNListParentPath on

	  # Authentication: Basic
	  AuthName "Subversion repository"
	  AuthType Basic
	  AuthBasicProvider file
	  AuthUserFile /home/svn/conf/htpasswd
	  Require valid-user

	  # Authorization: Path-based access control
	  AuthzSVNAccessFile /home/svn/conf/authz
	</Location>
	END

	#svn
	cat >/home/svnserve.conf.txt<<-END
	[general]
	anon-access = none
	#有效值是"write", "read",and "none".
	auth-access = write
	password-db = /home/svn/conf/passwd
	authz-db = /home/svn/conf/authz
	realm = /home/svn
	END

	cat >/home/authz.txt<<-END
	[groups]
	manager=$ADMIN
	users=$USER

	[/]
	@manager=rw
	*=

	[repos:/]
	@manager=rw
	@users=rw
	*=
	END

	if [ ! -d /home/svn/conf ]; then
		echo "create default repository"
		mkdir -p /home/svn/conf
		[ ! -d /home/svn/$REPOS ] && svnadmin create /home/svn/$REPOS && chown -R apache.apache /home/svn/$REPOS

		echo "$ADMIN:$(openssl passwd -apr1 $ADMIN_PASS)" > /home/svn/conf/htpasswd
		echo "$USER:$(openssl passwd -apr1 $USER_PASS)" >> /home/svn/conf/htpasswd
		echo -e "$ADMIN = $ADMIN_PASS\n$USER = $USER_PASS" |tee >/home/svn/conf/passwd

		\cp /home/svnserve.conf.txt /home/svn/conf/svnserve.conf
		\cp /home/authz.txt /home/svn/conf/authz
	else
		if [ -f /home/svn/conf/authz ]; then 
			echo "authz exist"
			for i in $(grep : /home/svn/conf/authz |grep -Po '(?<=\[)[^)]*(?=\])' |awk -F: '{print $1}'); do
				[ ! -d "/home/svn/$i" ] && svnadmin create /home/svn/$i && chown -R apache.apache /home/svn/$i && echo "create $i repository"
			done
		else
			\cp /home/authz.txt /home/svn/conf/authz
			[ ! -d /home/svn/$REPOS ] && svnadmin create /home/svn/$REPOS && chown -R apache.apache /home/svn/$REPOS && echo "create default repository"
		fi
	
		if [ -f /home/svn/conf/passwd ]; then
			echo "passwd exist"
			\rm /home/svn/conf/htpasswd 2>/dev/null || echo
			for i in $(sed 's/ //g' /home/svn/conf/passwd); do
				user=$(echo $i |awk -F= '{print $1}')
				pass=$(echo $i |awk -F= '{print $2}')
				echo "$user:$(openssl passwd -apr1 $pass)" >> /home/svn/conf/htpasswd && echo "$user = $pass"
			done
		else
			echo "$ADMIN:$(openssl passwd -apr1 $ADMIN_PASS)" > /home/svn/conf/htpasswd
			echo "$USER:$(openssl passwd -apr1 $USER_PASS)" >> /home/svn/conf/htpasswd
			echo -e "$ADMIN = $ADMIN_PASS\n$USER = $USER_PASS" |tee >/home/svn/conf/passwd
		fi
		\cp /home/svnserve.conf.txt /home/svn/conf/svnserve.conf
	fi
fi
	echo "Start ****"
	exec "$@"
else

    echo -e "
	Example:
				docker run -d \\
				-v /docker/svn:/home/svn \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-e REPOS=[repos] \\
				-e ADMIN=[admin] \\
				-e USER=[user1] \\
				-e ADMIN_PASS=[passwd0] \\
				-e USER_PASS=[passwd1] \\
				--hostname svn \\
				--name svn svn

	Or prepare /docker/svn/conf/authz and /docker/svn/conf/passwd files.
	"
fi
