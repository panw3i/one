FROM centos:latest
MAINTAINER The CentOS Project <admin@jiobxn.com>

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install tcl ruby-devel gcc-c++ make net-tools bash-completion vim wget iptables; yum clean all

RUN `#gem sources -r http://rubygems.org/ -a https://gems.ruby-china.org/` \
        && gem install json_pure \
        && gem update --system \
        && gem install bundler \
        && `#bundle config mirror.https://rubygems.org https://gems.ruby-china.org` \
        && gem install redis

RUN cd /usr/local/src \
        && wget -c $(curl -s http://redis.io/ |grep tar.gz |awk -F\' '{print $2}')

RUN cd /usr/local/src \
        && tar zxf redis-*.tar.gz \
        && cd /usr/local/src/redis-* \
        && make -j8 PREFIX=/usr/local/redis \
        && make PREFIX=/usr/local/redis install \
        && cp *.conf /usr/local/redis/ \
        && for i in $(find ./src/* -perm -755);do \cp $i /usr/local/redis/bin/;done \
        && ln -s /usr/local/redis/bin/* /usr/local/bin/ \
        && rm -rf /usr/local/src/*

VOLUME /usr/local/redis/data

COPY redis.sh /redis.sh
RUN chmod +x /redis.sh

ENTRYPOINT ["/redis.sh"]

EXPOSE 6379

CMD ["redis-server", "/usr/local/redis/redis.conf"]

# docker build -t redis .
# docker run -d --restart always --privileged -v /docker/redis:/usr/local/redis/data -p 16379:6379  -e REDIS_PASS=bigpass --hostname redis --name redis redis
# docker run -it --rm redis --help