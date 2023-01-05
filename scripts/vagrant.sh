#!/bin/bash -eux
#title			: vagrant.sh
#description	: This script configures the vagrant user
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			:
echo '==============================================='
echo '===>   Configuring settings for vagrant    <==='
echo '==============================================='

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

# See Vagrant documentation and take the key from https://github.com/hashicorp/vagrant/tree/master/keys
VAGRANT_INSECURE_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"

# Add vagrant user (if it doesn't already exist)
if ! id -u $SSH_USER >/dev/null 2>&1; then
    echo '==> Creating Vagrant user'
    /usr/sbin/groupadd $SSH_USER
    /usr/sbin/useradd $SSH_USER -g $SSH_USER -G sudo,cdrom,floppy,netdev,video,audio,plugdev,dip -d $SSH_USER_HOME --create-home
    echo "${SSH_USER}:${SSH_USER}" | chpasswd
fi

# Set up sudo.  Be careful to set permission BEFORE copying file to sudoers.d
( cat <<EOP
%$SSH_USER ALL=(ALL) NOPASSWD:ALL
EOP
) > /tmp/99_vagrant
chmod 0440 /tmp/99_vagrant
mv /tmp/99_vagrant /etc/sudoers.d/

# Packer passes boolean user variables through as '1', but this might change in
# the future, so also check for 'true'.
if [ "$INSTALL_VAGRANT_KEY" = "true" ] || [ "$INSTALL_VAGRANT_KEY" = "1" ]; then
    echo '===> Installing Vagrant SSH key <==='
    mkdir -pm 700 $SSH_USER_HOME/.ssh
    # https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
    echo "${VAGRANT_INSECURE_KEY}" > $SSH_USER_HOME/.ssh/authorized_keys
    chmod 600 $SSH_USER_HOME/.ssh/authorized_keys
	
	# Exit stuck sessions
	echo "Host *
  ServerAliveInterval 5
  ServerAliveCountMax 1" > $SSH_USER_HOME/.ssh/config
    chmod 600 $SSH_USER_HOME/.ssh/config

    chown -R $SSH_USER:$SSH_USER $SSH_USER_HOME/.ssh
fi

exit 0