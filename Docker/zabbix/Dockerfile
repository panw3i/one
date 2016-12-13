FROM centos:latest
MAINTAINER The CentOS Project <admin@jiobxn.com>

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN rpm -ivh http://repo.mysql.com/$(curl -s "http://dev.mysql.com/downloads/repo/yum/" |grep "noarch.rpm" |head -1 |grep -Po '(?<=\()[^)]*(?=\))')
RUN epel_url="http://dl.fedoraproject.org/pub/epel/$(awk '{print $4}' /etc/redhat-release |awk -F. '{print $1}')/x86_64/e/" \
        && rpm -ivh $epel_url$(curl -s $epel_url |grep "epel-release" |awk -F\" '{print $6}')
RUN yum clean all; yum -y update; yum -y install httpd mod_ssl net-tools bash-completion vim wget make gcc-c++ iptables cronie; yum -y install OpenIPMI-devel libssh2-devel unixODBC-devel iksemel-devel net-snmp-devel mysql-community-devel mysql-community-client libxml2-devel curl-devel java-1.8.0-openjdk-devel openldap-devel fping wqy-zenhei-fonts; yum clean all

RUN useradd -r -s /sbin/nologin zabbix \
        && cd /usr/local/src \
        && zabbix_down="https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/" \
        && zabbix_v=$(curl -s $zabbix_down |grep "tr title" |head -1 |awk -F\" '{print $2}') \
        && wget -c "$zabbix_down$zabbix_v/zabbix-$zabbix_v.tar.gz"

RUN cd /usr/local/src \
        && tar zxf zabbix-*.tar.gz \
        && cd /usr/local/src/zabbix-* \
        && ./configure --prefix=/usr/local/zabbix \
           --enable-server \
           --enable-agent \
           --enable-java \
           --with-mysql \
           --with-net-snmp \
           --with-libcurl \
           --with-libxml2 \
           --with-openipmi \
           --with-ssh2 \
           --with-iconv \
           --with-unixodbc \
           --with-jabber \
           --with-openssl \
           --with-ldap \
        && make install \
        && cp -a database/mysql /usr/local/zabbix/mysql \
        && cp -a frontends/php /usr/local/zabbix/php \
        && rm -rf /usr/local/src/* \
        && ln -s /usr/local/zabbix/sbin/zabbix_* /usr/local/bin/ \
        && ln -s /usr/local/zabbix/bin/* /usr/local/bin/

VOLUME /var/www/html

COPY zabbix-httpd.sh /zabbix.sh
RUN chmod +x /zabbix.sh

ENTRYPOINT ["/zabbix.sh"]

EXPOSE 80 443 10051

CMD ["httpd", "-DFOREGROUND"]

# docker build -t zabbix-httpd .
# docker run -d --restart always --privileged -p 11080:80 -p 11443:443 -p 20051:10051 -v /docker/www:/var/www/html -e PHP_SERVER=redhat.xyz -e ZBX_DB_SERVER=redhat.xyz -e ZBX_DB_PORT=13306 --hostname zabbix --name zabbix zabbix-httpd
# docker run -it --rm zabbix-httpd --help