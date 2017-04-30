#!/bin/sh 
SSH=$(egrep "Failed" /var/log/secure |awk '{print $(NF-3)}' |grep ^[1-9] |sort |uniq -c |awk '$1>10' |awk '{print $1"="$2}')  

for i in $SSH
do  
    NUMBER=`echo $i |awk -F= '{print $1}'`   
    SCANIP=`echo $i |awk -F= '{print $2}'`   
    echo "$SCANIP($NUMBER)"  

    if [ -z "`/sbin/iptables -vnL INPUT | grep $SCANIP`" ]   
    then   
        /sbin/iptables -I INPUT -s $SCANIP -j DROP
        ADDRESS=`/usr/bin/curl -s "http://ip138.com/ips138.asp?ip=$SCANIP&action=2"| iconv -f gb2312 -t utf-8|grep '<ul class="ul1"><li>' | awk -F '[<> ]+' '{print $7,$8}' | awk -F： '{print $2}'`
        echo "`date +%-F/%-H:%-M:%-S` $SCANIP($NUMBER) $ADDRESS" >> /var/log/scanip.log
    fi 
done
