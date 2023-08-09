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

# skel
mv /tmp/files/skel/.bashrc /etc/skel/.bashrc
chown root:root /etc/skel/.bashrc
mv /tmp/files/skel/.bash_logout /etc/skel/.bash_logout
chown root:root /etc/skel/.bash_logout
mv /tmp/files/skel/.profile /etc/skel/.profile
chown root:root /etc/skel/.profile

cp /etc/skel/.bashrc $HOME_DIR/.bashrc
cp /etc/skel/.bash_logout $HOME_DIR/.bash_logout
cp /etc/skel/.profile $HOME_DIR/.profile

# root
mv /tmp/files/root/.bash_profile /root/.bash_profile
chown root:root /root/.bash_profile

# vim
# mv /tmp/files/vim/vimrc.local /etc/vim/vimrc.local
# chown root:root /etc/vim/vimrc.local

# if IPv6 is disabled, Domain resolution could be very slow. We fix this:
echo options single-request-reopen >> /etc/resolv.conf

exit 0