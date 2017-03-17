SVN
===

## Example:

    docker run -d --restart always -p 10080:80 -p 10443:443 -p 13690:3690 -v /docker/svn:/home/svn --hostname svn --name svn svn

    #访问svn示例 http://redhat.xyz:10080/svn   用户名/密码：admin/passwd0  user1/paaswd1

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

        docker run -d \\
				-v /docker/svn:/home/svn \\
				-v /docker/key:/key \\
				-p 10080:80 \\
				-p 10443:443 \\
				-p 13690:3690 \\
				-e ADMIN=[admin] \\
				-e USER=[user1] \\
				-e ADMIN_PASS=[passwd0] \\
				-e USER_PASS=[passwd1] \\
				--hostname svn \\
				--name svn svn

提示：svn默认只创建两个用户和一个仓库，如果需要更复杂的权限和更多的用户，请提前准备好 authz、passwd 放入 svn/conf 目录。
