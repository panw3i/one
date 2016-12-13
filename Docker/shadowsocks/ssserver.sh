#!/bin/bash
set -e

: ${SS_PASS:=$(pwmake 64)}
: ${SS_EMOD:=aes-256-cfb}
: ${SS_PORT:=8443}

echo -e "password: $SS_PASS \nencryption mode: $SS_EMOD"

exec ssserver -p $SS_PORT -k $SS_PASS -m $SS_EMOD
