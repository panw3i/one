#!/bin/bash
#--------第一部分取值--------
##现有配置
GW=$(ip route |grep default |awk '{print $3}')
DEV=$(ip route |grep default |awk '{print $5}')
IP=$(ip route |grep $DEV |grep src |awk '{print $9}')
MASK=$(ip route |grep $DEV |grep src |awk '{print $1}' |awk -F/ '{print $2}')
DNS1=$(grep DNS1 /etc/sysconfig/network-scripts/ifcfg-$DEV |awk -F= '{print $2}')

##现有设备
dev=$(ip address |grep "BROADCAST" |head -1 |awk '{print $2}' |sed 's/..$//')
dev1=$(ip address |grep "BROADCAST" |head -1 |awk '{print $2}' |sed 's/.$//')
dev2=$(ip address |grep "BROADCAST" |head -2 |tail -1 |awk '{print $2}' |sed 's/.$//')
devn=$(grep MASTER /etc/sysconfig/network-scripts/ifcfg-$dev1 |awk -F= '{print $2}')

##设备状态
stat1=$(ip address |grep "BROADCAST" |head -1 |awk '{print $9}')
stat2=$(ip address |grep "BROADCAST" |head -2 |tail -1 |awk '{print $9}')

if [ $dev1 = $dev2 ];
then
    echo -e "---------Start a new Bonding! The "Need two network cards. BYE!"---------"
    exit 0
else
    echo -e "---------Start a new Bonding! The "$dev1 $stat1" + "$dev2 $stat2"---------"
fi

##IP地址
read  -p "IPADDR [ $IP ] "  ip
if [ -z $ip ]
then
ip=$IP
    if [ -z $ip ]
    then
    echo "none ip. BYE!"
    exit 0
    fi
fi

##子网掩码
read  -p "PREFIX [ $MASK ] "  mask
if [ -z $mask ]
then
mask=$MASK
    if [ -z $mask ]
    then
    echo "none netmask. BYE!"
    exit 0
    fi
fi

##网关
read  -p "GATEWAY [ $GW ] "  gw
if [ -z $gw ]
then
gw=$GW
    if [ -z $gw ]
    then
    echo "none gateway. BYE!"
    exit 0
    fi
fi

##DNS1
read  -p "DNS1 [ $DNS1 ] "  dns1
if [ -z $dns1 ]
then
dns1=$DNS1
    if [ -z $dns1 ]
    then
    dns1=114.114.114.114
    fi
fi

##Bond模式
echo -e "
modes: 
mode 0 (Balance Round Robin)
mode 1 (Active backup) [No switches support]
mode 2 (Balance XOR)
mode 3 (Broadcast)
mode 4 (802.3ad)
mode 5 (Balance TLB) [No switches support]
mode 6 (Balance ALB) [No switches support]"

read  -p "Default mode [ 5 ] "  mode
if [ -z $mode ]
then
mode=5
fi

##确认配置
echo -e "Bond $mode :
IPADDR=$ip
PREFIX=$mask
GATEWAY=$gw
DNS1=$dns1"

read -p "Write configuration?(y/n) [n]:" z
if [ "$z" != "y" ];
then
        echo "---------Not written configuration. BYE!---------"
        exit 0
else
        echo "---------Start write the configuration!---------"
fi


#--------第二部分写入配置--------
##备份配置文件
\mv /etc/sysconfig/network-scripts/ifcfg-$dev1 /etc/sysconfig/network-scripts/bak.ifcfg-$dev1 &> /dev/null
\mv /etc/sysconfig/network-scripts/ifcfg-$dev2 /etc/sysconfig/network-scripts/bak.ifcfg-$dev2 &> /dev/null
\mv /etc/sysconfig/network-scripts/ifcfg-$DEV /etc/sysconfig/network-scripts/bak.ifcfg-$DEV &> /dev/null
\mv /etc/sysconfig/network-scripts/ifcfg-$devn /etc/sysconfig/network-scripts/bk.ifcfg-$devn &> /dev/null

cat >/etc/sysconfig/network-scripts/ifcfg-$dev1<<END
DEVICE=$dev1
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
MASTER=bond$mode
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
END

cat >/etc/sysconfig/network-scripts/ifcfg-$dev2<<END
DEVICE=$dev2
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
MASTER=bond$mode
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
END

##创建bond
cat >/etc/sysconfig/network-scripts/ifcfg-bond$mode<<END
DEVICE=bond$mode
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=none
USERCTL=no
NM_CONTROLLED=no
BONDING_OPTS="mode=$mode miimon=100"
IPADDR0=$ip
PREFIX0=$mask
GATEWAY=$gw
DNS1=$dns1
DNS2=8.8.8.8
END

##加载模块
echo "alias bond$mode bonding" > /etc/modprobe.d/bond.conf


#--------第三部分验证配置--------
##是否重启网卡并测试网络
read -p "
Restart and test the network.
Connected to the network? ? (y/n) [n]:" x
if [ "$x" != "y" ];
then
        echo "---------BYE!---------"
        exit 0
fi

#自动恢复功能
cat >/root/check_bond.sh<<END
#!/bin/bash
ping -c8 $gw &> /dev/null

if [ \$? = 0 ];
then
    echo "---------OK!BYE!---------"
    sed -i '/check_bond.sh/d' /var/spool/cron/root
    exit 0

else
    \cp /etc/sysconfig/network-scripts/bak.ifcfg-$dev1 /etc/sysconfig/network-scripts/ifcfg-$dev1 &> /dev/null
    \cp /etc/sysconfig/network-scripts/bak.ifcfg-$dev2 /etc/sysconfig/network-scripts/ifcfg-$dev2 &> /dev/null
    \cp /etc/sysconfig/network-scripts/bak.ifcfg-$DEV /etc/sysconfig/network-scripts/ifcfg-$DEV &> /dev/null
    \cp /etc/sysconfig/network-scripts/bak.ifcfg-$devn /etc/sysconfig/network-scripts/ifcfg-$devn &> /dev/null
    /etc/init.d/network restart
    sleep 5
    sed -i '/check_bond.sh/d' /var/spool/cron/root
fi
END

chmod u+x /root/check_bond.sh
##两分钟后执行check.sh脚本
echo "*/2 * * * * /bin/bash /root/check_bond.sh" >> /var/spool/cron/root
/etc/init.d/network restart
echo "---------Congratulations! 祝贺! Goodbye.---------"
##
cat /proc/net/bonding/bond$mode |grep Mode
ethtool bond$mode |grep Speed