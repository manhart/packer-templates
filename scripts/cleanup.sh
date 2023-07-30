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

# Delete X11 libraries
echo "===> Removing X11 libraries <==="
apt-get -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6;

echo "===> Remove obsolete networking packages <==="
apt-get -y purge ppp pppconfig pppoeconf;

echo "===> Remove popularity-contest package <==="
apt-get -y purge popularity-contest;

echo "===> Cleaning up the apt cache <==="
apt-get -y autoremove --purge;
apt-get -y clean;
apt-get -y autoclean

# echo "==> Installed packages"
# dpkg --get-selections | grep -v deinstall

# truncate any logs that have built up during the install
echo "===> Reset any logs <==="
find /var/log -type f -exec truncate --size=0 {} \;

# Blank netplan machine-id (DUID) so machines get unique ID generated on boot.
truncate -s 0 /etc/machine-id
if test -f /var/lib/dbus/machine-id
then
  truncate -s 0 /var/lib/dbus/machine-id  # if not symlinked to "/etc/machine-id"
fi

echo "===> Removing caches <==="
find /var/cache -type f -delete

echo "===> Cleaning up tmp <==="
rm -rf /tmp/* /var/tmp/*

echo "===> Clearing last login information <==="
>/var/log/lastlog
>/var/log/wtmp
>/var/log/btmp

echo "===> Force a new random seed to be generated <==="
rm -f /var/lib/systemd/random-seed

# Remove Bash history
echo "===> Reset bash history <==="
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history
rm -f /root/.wget-hsts
export HISTSIZE=0


# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early
sync

exit 0