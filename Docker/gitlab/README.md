Gitlab
===

## Build Defult Parameter

        REDIS_SERVER="redhat.xyz"
        REDIS_PORT="16379"
        RUBY_V="2.3.1"
        GITLAB_V="8-14-stable"

    #也可以手动指定ARG参数
    docker build --build-arg REDIS_SERVER=jiobxn.com -t gitlab:8-14 .

    在国内的网络环境Build很容易失败，在Dockerfile开启更换Gem源

## Example:

    docker run -d --restart always --privileged -p 2222:22 -p 8888:8080 -v /docker/gitlab:/home/git/repositories -e REDIS_SERVER=redhat.xyz -e DB_SERVER=redhat.xyz -e HTTP_SERVER=redhat.xyz --hostname gitlab --name gitlab gitlab

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数


			docker run -d --restart always --privileged \\
			-p 2222:22 \\
			-p 8888:8080 \\
			-v /docker/gitlab:/home/git/repositories \\
			-e HTTP_SERVER=[SERVER_IP] \\    浏览器访问gitlab的IP,默认是公网IP
			-e HTTP_PORT=[8888] \\           浏览器访问gitlab的端口
			-e HTTPS=<Y> \\                  使用HTTPS，这时候gitlab是放在反向代理后面
			-e SSH_PORT=[2222] \\            ssh访问gitlab的端口
			-e REDIS_SERVER=<redhat.xyz> \\  redis服务器地址
			-e REDIS_PORT=[16379] \\         redis服务端口
			-e DB_SERVER=<redhat.xyz> \\     mysql服务器地址
			-e DB_PORT=[13306] \\            mysql服务端口
			-e DB_USER=[git] \\              mysql用户
			-e DB_PASS=[Newp@555] \\         mysql用户的密码
			-e DB_NAME=[gitlabhq_production] \\   mysql数据库名称
			-e SMTP_HOST=[smtp.exmail.qq.com] \\  SMTP服务器地址
			-e SMTP_USER=<gitlab@example.com> \\  登陆的邮箱
			-e SMTP_PASS=<password> \\            登陆邮箱的密码
			--hostname gitlab --name \\
			gitlab gitlab
