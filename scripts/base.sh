#!/bin/bash -eux
#title			: base.sh
#description	: This script will make the basic configuration / settings
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2021-05-15
#notes			: 
echo "==============================================="
echo "===>          Basic configuration          <==="
echo "==============================================="
echo "Hello, this is `whoami`"

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

# ssh
sed -i 's/^#Post 22$/Port 22/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin .*$/#PermitRootLogin no/' /etc/ssh/sshd_config

# skel
mv /tmp/files/skel/.bashrc /etc/skel/.bashrc
chown root:root /etc/skel/.bashrc
mv /tmp/files/skel/.bash_logout /etc/skel/.bash_logout
chown root:root /etc/skel/.bash_logout
mv /tmp/files/skel/.profile /etc/skel/.profile
chown root:root /etc/skel/.profile

cp /etc/skel/.bashrc $SSH_USER_HOME/.bashrc
cp /etc/skel/.bash_logout $SSH_USER_HOME/.bash_logout
cp /etc/skel/.profile $SSH_USER_HOME/.profile

# root
mv /tmp/files/root/.bash_profile /root/.bash_profile
chown root:root /root/.bash_profile

# vim
mv /tmp/files/vim/vimrc.local /etc/vim/vimrc.local
chown root:root /etc/vim/vimrc.local

exit 0