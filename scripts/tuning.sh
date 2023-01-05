#!/bin/bash -eaux
#title			: tuning.sh
#description	: This script will tune the system
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			:
echo '==============================================='
echo '===>             Tuning System             <==='
echo '==============================================='
sed -i 's/^#UseDNS no$/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^#GSSAPIAuthentication no$/GSSAPIAuthentication no/' /etc/ssh/sshd_config

sysctl vm.swappiness=1
echo "vm.swappiness=1" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf

# Exit stuck sessions
mkdir -pm 700 /root/.ssh
echo "Host *
  ServerAliveInterval 5
  ServerAliveCountMax 1" > /root/.ssh/config
chmod 600 /root/.ssh/config

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751636
apt-get install libpam-systemd

exit 0