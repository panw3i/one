FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN nginx_url="http://nginx.org/packages/centos/$(awk '{print $4}' /etc/redhat-release |awk -F. '{print $1}')/noarch/RPMS/" \
        && rpm -ivh $nginx_url$(curl -s $nginx_url |grep release |awk -F\" '{print $2}')
RUN yum clean all; yum -y update; yum -y install nginx net-tools bash-completion vim wget cronie iptables cronie; yum clean all

VOLUME /key

COPY nproxy.sh /nproxy.sh
RUN chmod +x /nproxy.sh

ENTRYPOINT ["/nproxy.sh"]

EXPOSE 80 443

CMD ["nginx"]

# docker build -t nproxy .
# docker run -d --restart always -p 80:80 -p 443:443 -v /docker/nproxy:/key -e PROXY_HTTPS=Y -e NGX_DOMAIN=fqhub.com --hostname nproxy --name nproxy nproxy
# docker run -it --rm nproxy --help
