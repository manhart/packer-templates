#!/bin/bash -eux
#title			: base.sh
#description	: This script will make the basic configuration / settings
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			: 
echo "==============================================="
echo "===>          Basic configuration          <==="
echo "==============================================="
echo "Hello, this is `whoami`"

SSH_USER=${SSH_USERNAME:-vagrant}
HOME_DIR=${HOME_DIR:-/home/${SSH_USER}}

# secure ssh
sed -i 's/^#Post 22$/Port 22/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin .*$/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication .*$/PasswordAuthentication no/' /etc/ssh/sshd_config

# skel
mv /tmp/files/skel/.bashrc /etc/skel/.bashrc
chown root:root /etc/skel/.bashrc
mv /tmp/files/skel/.bash_logout /etc/skel/.bash_logout
chown root:root /etc/skel/.bash_logout
mv /tmp/files/skel/.profile /etc/skel/.profile
chown root:root /etc/skel/.profile
mv /tmp/files/profile.d/scripts-path.sh /etc/profile.d/scripts-path.sh
chown root:root /etc/profile.d/scripts-path.sh
chmod 755 /etc/profile.d/scripts-path.sh

cp /etc/skel/.bashrc $HOME_DIR/.bashrc
cp /etc/skel/.bash_logout $HOME_DIR/.bash_logout
cp /etc/skel/.profile $HOME_DIR/.profile

# root
mv /tmp/files/root/.bash_profile /root/.bash_profile
chown root:root /root/.bash_profile

# vim
mv /tmp/files/vim/vimrc.local /etc/vim/vimrc.local

# /opt/scripts
echo "Configure /opt/scripts"
mkdir -p /opt/scripts

# Script to generate self signed ssl certificates
mv /tmp/files/scripts/generate_ssl_crt.sh /opt/scripts/generate_ssl_crt
chmod ugo+x /opt/scripts/generate_ssl_crt
chown root:root /opt/scripts/generate_ssl_crt

# Script to setup Apache VHosts
mv /tmp/files/scripts/setup_vhosts.sh /opt/scripts/setup_vhosts
chmod ugo+x /opt/scripts/setup_vhosts
chown root:root /opt/scripts/setup_vhosts

# Script to enable custom apache configs
mv /tmp/files/scripts/a2encustomconf /opt/scripts/a2encustomconf
chmod ugo+x /opt/scripts/a2encustomconf
chown root:root /opt/scripts/a2encustomconf

# Script to disable custom apache configs
mv /tmp/files/scripts/a2discustomconf /opt/scripts/a2discustomconf
chmod ugo+x /opt/scripts/a2discustomconf
chown root:root /opt/scripts/a2discustomconf

# custom configuration files for all vhosts
mkdir -p /etc/apache2/custom-available
mkdir -p /etc/apache2/custom-enabled

# vim
# mv /tmp/files/vim/vimrc.local /etc/vim/vimrc.local
# chown root:root /etc/vim/vimrc.local

# if IPv6 is disabled, Domain resolution could be very slow.
# echo options single-request-reopen >> /etc/resolv.conf

exit 0