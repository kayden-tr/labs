#!/bin/bash

genpasswd() {
local l=$1
[ "$1" == "" ] && l=20 #If no length is provided, default to 20
tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${1} | xargs
}
genpasswd $1