#!/bin/bash

WWW="/var/www/html"
DIR="h5"
TIME="$(date +%F_%T)"

for i in $(find $DIR -type d); do
	if [ ! -d "$WWW/$i" ]; then
		[ "$1" == "L" ] && echo -e "$WWW/$i  \033[32m Add Directory \033[0m"
		[ "$1" == "yes" ] && mkdir "$WWW/$i"
#		[ "$1" == "yes" ] && mkdir -p "$TIME/$i"
	fi
done

for i in $(find $DIR -type f); do
	if [ -f "$WWW/$i" ]; then
		[ "$1" == "L" ] && echo -e "$WWW/$i  \033[34m Update File \033[0m"
		[ "$1" == "yes" ] && cp "$WWW/$i" "$WWW/$i-$(date +%F_%T)" && \cp $i "$WWW/$i"
#		[ "$1" == "yes" ] && cp "$WWW/$i" "$TIME/$i" && \cp $i "$WWW/$i"
	else
		[ "$1" == "L" ] && echo -e "$WWW/$i  \033[32m Add File \033[0m"
		[ "$1" == "yes" ] &&  \cp $i "$WWW/$i"
	fi
done
