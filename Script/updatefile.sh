#!/bin/bash

www="/var/www/html"
dir="h5"

for i in $(find $dir -type d); do
	if [ ! -d "$www/$i" ]; then
		[ "$1" == "L" ] &&  echo -e "$www/$i  \033[34m Add Directory \033[0m"
		[ "$1" == "yes" ] &&  mkdir "$www/$i"
	fi
done

for i in $(find $dir -type f); do
        if [ -f "$www/$i" ]; then
		[ "$1" == "L" ] &&  echo -e "$www/$i  \033[32m Update File \033[0m"
		[ "$1" == "yes" ] &&  cp "$www/$i" "$www/$i-$(date +%F_%T)" && \cp $i "$www/$i"
        else
		[ "$1" == "L" ] &&  echo -e "$www/$i  \033[34m Add File \033[0m"
		[ "$1" == "yes" ] &&  \cp $i "$www/$i"
        fi
done
