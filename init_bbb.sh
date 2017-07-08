#!/bin/bash

# Usage sudo init_bbb.sh <username>

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

cp -r ./etc /
cp -r ./usr /
cp -r ./home/.bashrc /home/$1/.bashrc
chown $1:$1 /home/$1/.bashrc

groupadd -f cape
groupadd -f gpio

usermod -a -G cape $USER
usermod -a -G gpio $USER

systemctl enable capemgr_usr.service
