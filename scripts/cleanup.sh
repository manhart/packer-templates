#!/bin/bash -eux
#title			: cleanup.sh
#description	: This script will cleanup the system 
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			:
echo ''
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '===>                        Cleanup                        <==='
echo '==============================================================='
echo ''

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "===> Cleaning up udev rules <==="
rm -rf /dev/.udev/

# Better fix that persists package updates: http://serverfault.com/a/485689
touch /etc/udev/rules.d/75-persistent-net-generator.rules

echo "===> Cleaning up leftover dhcp leases <==="
if [ -d "/var/lib/dhcp" ]; then
    rm /var/lib/dhcp/*
fi

echo "===> Cleaning up tmp <==="
rm -rf /tmp/*

# Delete X11 libraries
#echo "===> Removing X11 libraries <==="
#apt-get -yq purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6;

echo "===> Cleaning up the apt cache <==="
apt-get -y autoremove --purge;
apt-get -y clean;
apt-get -y autoclean

# echo "==> Installed packages"
# dpkg --get-selections | grep -v deinstall

# Remove Bash history
echo "===> Reset bash history <==="
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history
rm -f /root/.wget-hsts

# truncate any logs that have built up during the install
echo "===> Reset any logs <==="
find /var/log -type f -exec truncate --size=0 {} \;

# Blank netplan machine-id (DUID) so machines get unique ID generated on boot.
truncate -s 0 /etc/machine-id

echo "===> Removing caches <==="
find /var/cache -type f -delete

echo "===> Clearing last login information <==="
>/var/log/lastlog
>/var/log/wtmp
>/var/log/btmp

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early
sync

exit 0