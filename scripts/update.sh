#!/bin/bash -eux
#title			: update.sh
#description	: This script updates packages
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2021-04-03
#notes			:
echo "==============================================="
echo "===>   Updating list of repositories and   <==="
echo "===>          Upgrading packages           <==="
echo "==============================================="

# apt-get update does not actually perform updates, it just downloads and indexes the list of packages
apt-get -yqq update
apt-get -yqq upgrade

exit 0