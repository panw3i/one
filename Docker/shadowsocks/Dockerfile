FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum -y install epel-release; yum -y update; yum -y install python34-setuptools; yum clean all
RUN easy_install-3.4 pip; pip3.4 install --upgrade pip; pip3.4 install shadowsocks

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
