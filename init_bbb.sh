#!/bin/bash

# Usage sudo init_bbb.sh

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

cp -r ./etc/ /etc/
cp -r ./usr/ /usr/
