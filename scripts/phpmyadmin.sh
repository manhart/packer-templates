#!/bin/bash -eux
#title			: phpmyadmin.sh
#description	: This script installs phpmyadmin
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			:
echo ''
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '===>                  Install PhpMyAdmin                   <==='
echo '==============================================================='
echo ''
# Download and extract phpmyadmin

VER="5.2.1"
wget --no-verbose https://files.phpmyadmin.net/phpMyAdmin/$VER/phpMyAdmin-$VER-all-languages.tar.gz -P /tmp
tar -xzf /tmp/phpMyAdmin-$VER-all-languages.tar.gz

# move to /usr/share
mv phpMyAdmin-$VER-all-languages /usr/share/phpmyadmin/

# create the tmp directories
mkdir -p /var/lib/phpmyadmin
mkdir -p /var/lib/phpmyadmin/tmp

chown www-data:www-data /var/lib/phpmyadmin/tmp
chmod 770 /var/lib/phpmyadmin/tmp

# config.inc.php

randomBlowfishSecret=$(openssl rand -base64 32)
sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = base64_decode('$randomBlowfishSecret')|" /tmp/files/phpmyadmin/config.inc.php > /usr/share/phpmyadmin/config.inc.php

# configure the vhost
mv /tmp/files/phpmyadmin/apache.conf /etc/apache2/sites-available/pinned-phpmyadmin.conf
chown root:root /etc/apache2/sites-available/pinned-phpmyadmin.conf

# enable alias /phpmyadmin
a2ensite pinned-phpmyadmin

exit 0