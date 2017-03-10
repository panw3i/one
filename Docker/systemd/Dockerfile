FROM centos:latest
MAINTAINER "The CentOS Project" <admin@redhat.xyz>

ENV container docker

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN rpm -ivh "http://repo.mysql.com/$(curl -s http://repo.mysql.com/ |grep "$(uname -a |awk -F. '{print $(NF-1)}')" |awk -F\"  'END{print $6}')"
RUN epel_url="http://dl.fedoraproject.org/pub/epel/$(awk '{print $4}' /etc/redhat-release |awk -F. '{print $1}')/x86_64/e/"; \
    rpm -ivh $epel_url$(curl -s $epel_url |grep "epel-release" |awk -F\" '{print $6}')
RUN yum -y update; yum clean all
RUN yum -y install systemd bash-completion vim wget initscripts iptables-services bind-utils iftop iproute net-tools cronie at mtr nmap tcpdump openssl perl perl-Data-Dumper automake libtool git mysql-community-devel mysql-community-client; yum clean all; \
    (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN git clone https://github.com/akopytov/sysbench.git \
    && cd sysbench \
    && ./autogen.sh \
    && ./configure \
    && make -j8 \
    && make install \
    && cd .. \
    && rm -rf sysbench

RUN system_v=$(awk '{print $4}' /etc/redhat-release |awk -F. '{print $1}') \
    && xtrabackup_url="https://www.percona.com/downloads/XtraBackup/" \
    && xtrabackup_v=$(curl -s $xtrabackup_url |grep selected |awk -F\" 'NR==1{print $2}' |awk -F- '{print $3}') \
    && xtrabackup_down=$(curl -s $xtrabackup_url/Percona-XtraBackup-$xtrabackup_v/binary/redhat/$system_v/ |sed 's/href=/\n/g' |grep rpm |awk -F\" 'NR==1{print $2}') \
    && yum install https://www.percona.com/$xtrabackup_down perl-Digest-MD5 -y
    
VOLUME ["/sys/fs/cgroup"]

COPY init.sh /init.sh
RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]

CMD ["/usr/sbin/init"]

# docker build -t systemd .
# docker run -d --restart always --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name systemd systemd
# docker run -d --restart always --privileged -v /docker/mysql-mini:/var/lib/mysql -v /docker/mysql-mini2:/xtrabackup -e MYSQL_ROOT_PASSWORD=newpass --name systemd systemd xtrabackup
