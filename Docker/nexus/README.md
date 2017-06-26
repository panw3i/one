Nexus Repository Manager
===

## Example:

    docker run -d --restart unless-stopped -p 8081:8081 -v /docker/nexus:/usr/local/sonatype-work --name nexus nexus

## Run Defult Parameter
**协定：** []是默参数，<>是自定义参数

				docker run -d \\
				-v /docker/nexus:/usr/local/sonatype-work \\
				-p 8081:8081 \\
				-e RUN_MEM=[1200M] \\
				-e MAX_MEM=[2G] \\
				-e NEXUS_PORT=[8081] \\
				-e URI_PATH=[/] \\
				--hostname nexus --name nexus nexus
