#!/bin/bash -eux
#title			: systemd.sh
#description	: This script will make the basic configuration / settings
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2023-07-30
#notes			: 
echo "==============================================="
echo "===>        ssh session workaround         <==="
echo "==============================================="
echo "ssh sessions are not cleanly terminated on shutdown/restart with systemd, so we install libpam-systemd"

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751636
apt-get install libpam-systemd

exit 0