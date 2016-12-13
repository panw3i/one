FROM centos:latest
MAINTAINER The CentOS Project <admin@jiobxn.com>

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN epel_url="http://dl.fedoraproject.org/pub/epel/$(awk '{print $4}' /etc/redhat-release |awk -F. '{print $1}')/x86_64/e/" \
        && rpm -ivh $epel_url$(curl -s $epel_url |grep "epel-release" |awk -F\" '{print $6}')
RUN yum clean all; yum -y update; yum -y install python-pip net-tools bash-completion vim wget iptables; yum clean all
RUN pip install --upgrade pip; pip install shadowsocks

COPY ssserver.sh /ssserver.sh
RUN chmod +x /ssserver.sh

EXPOSE 8443

ENTRYPOINT ["/ssserver.sh"]
# docker build -t shadowsocks .
# docker run -d --restart always -p 8443:8443 --hostname shadowsocks --name shadowsocks shadowsocks
# docker logs shadowsocks

#CMD ["ssserver"]
# docker build -t shadowsocks .
# docker run -d --restart always -p 8443:8443 --hostname shadowsocks --name shadowsocks shadowsocks -p 8443 -k password -m aes-256-cfb