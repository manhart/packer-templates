#!/bin/bash -eux
#title			: motd.sh
#description	: This script will install the LAMP stack
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2021-04-03
#notes			:
echo "==> Recording box generation date"
date > /etc/vagrant_box_build_date

echo "==============================================="
echo "===>    Customizing message of the day     <==="
echo "==============================================="
MOTD_FILE=/etc/motd
BANNER_WIDTH=64
PLATFORM_RELEASE=$(lsb_release -sd)
PLATFORM_MSG=$(printf '%s' "$PLATFORM_RELEASE")
BUILT_MSG=$(printf 'built %s' $(date +%Y-%m-%d))
# printf '%0.1s' "-"{1..64} > ${MOTD_FILE}
# printf '\n' >> ${MOTD_FILE}
# printf '%2s%-30s%30s\n' " " "${PLATFORM_MSG}" "${BUILT_MSG}" >> ${MOTD_FILE}
# printf '%0.1s' "-"{1..64} >> ${MOTD_FILE}
# printf '\n' >> ${MOTD_FILE}

exit 0