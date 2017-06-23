FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools iproute bash-completion vim wget git file rng-tools ldns-devel bzip2 make gcc autoconf bind bind-utils iptables cronie; yum clean all

RUN cd /usr/local/src \
        && wget -c $(curl -s http://libevent.org/ |grep stable.tar.gz |awk -F\" 'NR==1{print $4}') \
        && wget -c https://download.libsodium.org/libsodium/releases/LATEST.tar.gz \
        && git clone --recursive git://github.com/cofyc/dnscrypt-wrapper.git \
        && wget -c https://github.com/$(curl -s https://github.com/jedisct1/dnscrypt-proxy/releases |grep tar.bz2 |awk -F\" 'NR==1{print $2}')

RUN cd /usr/local/src \
        && tar zxf libevent-*.tar.gz \
        && tar zxf LATEST.tar.gz \
        && tar jxf dnscrypt-proxy-*.tar.bz2 \
        && \rm *.tar.* \
        && cd /usr/local/src/libevent-* \
        && ./configure && make -j8 && make install \
        && cd /usr/local/src/libsodium-* \
        && ./configure && make -j8 && make install \
        && cd /usr/local/src/dnscrypt-wrapper \
        && make configure && ./configure && make install \
        && echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf && ldconfig \
        && cd /usr/local/src/dnscrypt-proxy-* \
        && ./configure && make -j8 && make install \
        && rm -rf /usr/local/src/*

VOLUME /key /var/named/data

COPY dnscrypt.sh /dnscrypt.sh
RUN chmod +x /dnscrypt.sh

WORKDIR /key

ENTRYPOINT ["/dnscrypt.sh"]

EXPOSE 5443 53/udp

CMD ["dnscrypt"]

# docker build -t dnscrypt .
# docker run -d --restart unless-stopped -p 53:53/udp --name dns dnscrypt
# docker run -it --rm dnscrypt --help
