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

wget --no-verbose https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.tar.gz -P /tmp
tar -xzf /tmp/phpMyAdmin-5.2.0-all-languages.tar.gz

# move to /usr/share
mv phpMyAdmin-5.2.0-all-languages /usr/share/phpmyadmin/

# create the tmp directories
mkdir -p /var/lib/phpmyadmin
mkdir -p /var/lib/phpmyadmin/tmp

chown www-data:www-data /var/lib/phpmyadmin/tmp
chmod 770 /var/lib/phpmyadmin/tmp

# config.inc.php

randomBlowfishSecret=$(openssl rand -base64 32)
sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$randomBlowfishSecret'|" /tmp/files/phpmyadmin/config.inc.php > /usr/share/phpmyadmin/config.inc.php

# configure the vhost
mv /tmp/files/phpmyadmin/apache.conf /etc/apache2/sites-available/phpmyadmin.conf

# enable alias /phpmyadmin
a2ensite phpmyadmin.conf

exit 0