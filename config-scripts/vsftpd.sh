#!/bin/bash

# Determine the Path
function realpath() {
    local r=$1; local t=$(readlink $r)
    while [ $t ]; do
        r=$(cd $(dirname $r) && cd $(dirname $t) && pwd -P)/$(basename $t)
        t=$(readlink $r)
    done
    echo $r
}

MY_DIR=`dirname $(realpath $0)`
BACKUP=$MY_DIR/../backups
CONFIG=$MY_DIR/../config

if [ ! -e $BACKUP ]; then 
   echo Backup directory not found.  Cannot continue.
   exit 1
fi

if [ -f /etc/vsftpd/vsftpd.conf -a ! -f "$BACKUP/vsftpd.conf.orig" ]; then
	cp /etc/vsftpd/vsftpd.conf $BACKUP/vsftpd.conf.orig
fi

#### VSFTPD CONFIGURATION
# only copy the config file in place if the directory exists
if [ -d /etc/vsftpd ]; then
	cp -f $CONFIG/vsftpd.conf /etc/vsftpd/vsftpd.conf
fi
