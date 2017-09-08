FROM alpine:latest
MAINTAINER "The Alpine Project" <admin@jiobxn.com>
ARG LATEST="0"

RUN apk update && apk add python2 curl openssl libsodium tzdata bash && rm -rf /var/cache/apk/*
RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#Use pip to install: apk add py2-pip && pip install shadowsocks
RUN cd / \
        && wget -c https://github.com/$(curl -s https://github.com/shadowsocks/shadowsocks/releases |grep tar.gz |awk -F\" 'NR==1{print $2}') -O /shadowsocks.tar.gz \
        && wget -c https://github.com/$(curl -s https://github.com/shadowsocksr-backup/shadowsocksr-csharp/releases |grep tar.gz |awk -F\" 'NR==1{print $2}') -O /shadowsocksr.tar.gz \
        && tar zxf shadowsocks.tar.gz \
        && tar zxf shadowsocksr.tar.gz \
        && mv shadowsocks-* shadowsocks \
        && mv shadowsocksr-* shadowsocksr \
        && \rm *.tar.gz

COPY ssserver.sh /ssserver.sh
RUN chmod +x /ssserver.sh

EXPOSE 8443

ENTRYPOINT ["/ssserver.sh"]

CMD ["shadowsocks"]

# docker build -t shadowsocks .
# docker run -d --restart always -p 8443:8443 --hostname shadowsocks --name shadowsocks shadowsocks
# docker logs shadowsocks
