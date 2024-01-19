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

sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
#MariaDB (https://github.com/major/MySQLTuner-perl)
sysctl fs.aio-max-nr=1048576
echo "# MariaDB relevant, default was 65536
fs.aio-max-nr = 1048576
# default 100
vm.vfs_cache_pressure=50
# default 60
vm.swappiness=10
# default 3000 (30s)
vm.dirty_expire_centisecs=4000" >> /etc/sysctl.d/10-tuning.conf

# Exit stuck sessions
mkdir -pm 700 /root/.ssh
echo "Host *
  ServerAliveInterval 5
  ServerAliveCountMax 1" > /root/.ssh/config
chmod 600 /root/.ssh/config

echo "==============================================="
echo "===>        ssh session workaround         <==="
echo "==============================================="
echo "ssh sessions are not cleanly terminated on shutdown/restart with systemd, so we install libpam-systemd"
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751636
apt-get install libpam-systemd

exit 0