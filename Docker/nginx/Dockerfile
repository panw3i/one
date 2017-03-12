FROM centos:latest
MAINTAINER "The CentOS Project" <admin@jiobxn.com>

RUN \cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN yum clean all; yum -y update; yum -y install net-tools bash-completion vim wget make gcc-c++ iptables cronie geoip-devel libxml2-devel libxslt-devel gd-devel; yum clean all

RUN cd /usr/local/src \
        && pcre_down="https://sourceforge.net/projects/pcre/files/pcre/" && pcre_v=$(curl -s $pcre_down |grep "tr title" |awk -F\" 'NR==1{print $2}') && wget -c "$pcre_down$pcre_v/pcre-$pcre_v.tar.gz" \
        && openssl_down="ftp://ftp.openssl.org/source/" && openssl_v=$(curl -s $openssl_down |grep "tar.gz$" |egrep -v "pre|fips" |awk 'END{print $NF}') && wget -c "$openssl_down$openssl_v" \
        && wget -c http://zlib.net/$(curl -s http://zlib.net/ |grep "\.tar.gz" |awk -F\" 'NR==1{print $2}') \
        && wget -c $(curl -s http://www.cpan.org/src/ |grep wget |awk -F\" '{print $2}') \
        && nginx_v=$(curl -s http://nginx.org/ |grep "td class" |awk -F'html' 'NR==1{print $2}' |grep -Po '(?<=\>)[^)]*(?=\<)') && wget -c http://nginx.org/download/$nginx_v.tar.gz
        
RUN cd /usr/local/src \
        && tar zxf nginx-*.tar.gz \
        && tar zxf pcre-*.tar.gz \
        && tar zxf openssl-*.tar.gz \
        && tar zxf zlib-*.tar.gz \
        && tar zxf perl-*.tar.gz \
        && \rm *.tar.gz \
        && mv pcre-* pcre \
        && mv zlib-* zlib \
        && mv openssl-* openssl \
        && cd /usr/local/src/zlib \
        && ./configure && make -j8 && make install \
        && cd /usr/local/src/perl-* \
        && ./Configure -des && make -j8 && make install \
        && cd /usr/local/src/openssl \
        && ./config --prefix=/usr/local zlib threads shared  && make -j8 && make install \
        && echo "/usr/local/lib64" >> /etc/ld.so.conf && ldconfig \
        && cd /usr/local/src/nginx-* \
        && sed -i 's/\.openssl\/include/include/' auto/lib/openssl/conf \
        && sed -i 's/\.openssl\/lib\///' auto/lib/openssl/conf \
        && ./configure --prefix=/usr/local/nginx \
           --with-pcre=/usr/local/src/pcre \
           --with-zlib=/usr/local/src/zlib \
           --with-openssl=/usr/local/src/openssl \
           --with-threads \
           --with-file-aio \
           --with-http_ssl_module \
           --with-http_v2_module \
           --with-http_realip_module \
           --with-http_addition_module \
           --with-http_xslt_module \
           --with-http_image_filter_module \
           --with-http_geoip_module \
           --with-http_sub_module \
           --with-http_dav_module \
           --with-http_flv_module \
           --with-http_mp4_module \
           --with-http_gunzip_module \
           --with-http_gzip_static_module \
           --with-http_auth_request_module \
           --with-http_random_index_module \
           --with-http_secure_link_module \
           --with-http_degradation_module \
           --with-http_slice_module \
           --with-http_stub_status_module \
           --with-http_perl_module \
           --with-mail \
           --with-mail_ssl_module \
           --with-stream \
           --with-stream_ssl_module \
        && make -j8 && make install \
        && rm -rf /usr/local/src/* \
        && ln -s /usr/local/nginx/sbin/* /usr/local/bin/

VOLUME /usr/local/nginx/html /key

COPY nginx.sh /nginx.sh
RUN chmod +x /nginx.sh

ENTRYPOINT ["/nginx.sh"]

EXPOSE 80 443

CMD ["nginx"]

# docker build -t nginx .
# docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/www:/usr/local/nginx/html -e PHP_SERVER=redhat.xyz:9000 --hostname nginx --name nginx nginx
# docker run -d --restart always -p 10080:80 -p 10443:443 -v /docker/webapps:/usr/local/nginx/html -e TOMCAT_SERVER=redhat.xyz:18080 --hostname nginx --name nginx nginx
# docker run -it --rm nginx --help
