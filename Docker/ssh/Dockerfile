FROM centos:latest
MAINTAINER The CentOS Project <admin@jiobxn.com>

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN epel_url="http://dl.fedoraproject.org/pub/epel/$(awk '{print $4}' /etc/redhat-release |awk -F. '{print $1}')/x86_64/e/" \
        && rpm -ivh $epel_url$(curl -s $epel_url |grep "epel-release" |awk -F\" '{print $6}')
RUN yum clean all; yum -y update; yum -y install openssh-server bash-completion vim wget initscripts iptables bind-utils iftop iproute net-tools ntp cronie psmisc mtr nmap tcpdump openssl make gcc-c++ unzip bzip2 mailx bc at telnet git lsof; yum clean all

COPY ssh.sh /ssh.sh
RUN chmod +x /ssh.sh

ENTRYPOINT ["/ssh.sh"]

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]

# docker build -t ssh .
# docker run -d --restart always --privileged -p 2222:22 --hostname ssh --name ssh -e USER=root -e PASS=123456 ssh
# docker logs ssh |grep "ssh username password"
# ssh -p 2222 root@localhost