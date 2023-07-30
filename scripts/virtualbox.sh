#!/bin/bash -eux
#title			: virtualbox.sh
#description	: This script installs the guest additions
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			:
SSH_USER=${SSH_USERNAME:-vagrant}
HOME_DIR=${HOME_DIR:-/home/${SSH_USER}}

if [[ $PACKER_BUILDER_TYPE =~ virtualbox ]]; then
	echo "==============================================="
    echo "===> Installing VirtualBox guest additions <==="
	echo "==============================================="
    apt-get install -yqq linux-headers-$(uname -r) build-essential dkms bzip2 tar
    apt-get install -yqq libxt6 libxmu6

    VBOX_VERSION=$(cat $HOME_DIR/.vbox_version)
	ISO=VBoxGuestAdditions_${VBOX_VERSION}.iso
    mount -o loop $HOME_DIR/$ISO /mnt
    /mnt/VBoxLinuxAdditions.run --nox11 || true

    umount /mnt
    rm $HOME_DIR/$ISO
    rm $HOME_DIR/.vbox_version
	
    if ! modinfo vboxsf >/dev/null 2>&1; then
        echo "Cannot find vbox kernel module. Installation of guest additions unsuccessful!"
		exit 1
    fi
fi

exit 0