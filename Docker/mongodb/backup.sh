#!/bin/bash
PASS=newpass
BDAY=3

[ ! -d "/var/lib/mongo/mongo_back" ] && mkdir "/var/lib/mongo/mongo_back"

cd "/var/lib/mongo/mongo_back"
/usr/local/bin/mongodump -u root -p "$PASS" -o "$(date +%F)" 2>/dev/null
tar czf "$(date +%F)".tar.gz "$(date +%F)"
rm -rf "$(date +%F)"

#Retains the most recent 3-day backup
find "/var/lib/mongo/mongo_back/" -mtime +$BDAY -type f -name "*.tar.gz" -exec \rm {} \; 2>/dev/null
