#!/bin/sh

PATH='/sbin:/bin'
basedir=/sys$2
devpath=$1

if [ "$1" = "enable" ] ; then
    for f in export unexport ; do
        chmod g+w $basedir/$f
        chown :pwm $basedir/$f
    done
else
    for f in duty_cycle enable period polarity ; do
        chmod g+w /sys${devpath}/$f
        chown :pwm /sys${devpath}/$f
    done
fi
exit 0
