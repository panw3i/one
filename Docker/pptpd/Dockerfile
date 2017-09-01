FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum -y install epel-release; yum -y update; yum -y install pptpd iptables cronie net-tools bash-completion vim; yum clean all

VOLUME /key

COPY pptpd.sh /pptpd.sh
RUN chmod +x /pptpd.sh

ENTRYPOINT ["/pptpd.sh"]

EXPOSE 1723

CMD ["pptpd", "-f"]

# docker build -t pptpd .
# docker run -d --restart always --privileged --network=host -e VPN_PASS=123456 --hostname=pptpd --name=pptpd pptpd
# docker logs pptpd
