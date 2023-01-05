#!/bin/bash -eux
#title			: virtualbox.sh
#description	: This script installs the guest additions
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			:
SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
	echo "==============================================="
    echo "===> Installing VirtualBox guest additions <==="
	echo "==============================================="
    apt-get install -yqq linux-headers-$(uname -r) build-essential perl
    apt-get install -yqq libxt6 libxmu6

    VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
    mount -o loop $SSH_USER_HOME/VBoxGuestAdditions_${VBOX_VERSION}.iso /mnt
    sh /mnt/VBoxLinuxAdditions.run --nox11
    umount /mnt
    rm $SSH_USER_HOME/VBoxGuestAdditions_${VBOX_VERSION}.iso
    rm $SSH_USER_HOME/.vbox_version
fi

exit 0