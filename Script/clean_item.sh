#!/bin/bash

USER=admin
PASS=zabbix
APIURL=http://192.168.0.118/api_jsonrpc.php

SESSIONID=$(curl -s -X POST -H 'Content-Type:application/json' -d '{"jsonrpc": "2.0", "method": "user.login", "params": {"user": "'$USER'", "password": "'$PASS'"}, "id": 1, "auth": null}' $APIURL |python -m json.tool |grep result |awk -F\" '{print $4}')
HOSTID=$(curl -s -X POST -H 'Content-Type:application/json' -d '{"jsonrpc": "2.0", "method": "host.get", "params": {"output": ["hostid", "host"], "selectInterfaces": ["interfaceid", "ip"]}, "id": 1, "auth": "'$SESSIONID'"}' $APIURL |python -m json.tool |grep hostid |awk -F\" '{print $4}')

for i in $HOSTID; do
    ITEMID=$(curl -s -X POST -H 'Content-Type:application/json' -d '{"jsonrpc": "2.0", "method": "item.get", "params": {"output": "itemids", "hostids": "'$i'", "filter": {"state": "1"}}, "auth": "'$SESSIONID'", "id": 1}' $APIURL |python -m json.tool |grep itemid |awk -F: '{print $2}')
    for i in $ITEMID; do
        curl -s -X POST -H 'Content-Type:application/json' -d '{"jsonrpc": "2.0", "method": "item.delete", "params": ['$i'], "auth": "'$SESSIONID'", "id": 1}' $APIURL 1>/dev/null
    done
done
