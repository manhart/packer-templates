#!/bin/bash -eux
#title			: php-xdebug.sh
#description	: This script installs xdebug
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2021-05-15
#notes			:
echo ''
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '===>          Install xdebug for all PHP versions          <==='
echo '==============================================================='
echo ''
# https://stackoverflow.com/questions/40419718/how-to-install-php-extension-using-pecl-for-specific-php-version-when-several-p

# xdebug settings
mv /tmp/files/profile.d/xdebug.sh /etc/profile.d/xdebug.sh

# global directory for xdebug output
DIR_XDEBUG_OUTPUT_DIR=/vagrant/xdebug
mkdir -p DIR_XDEBUG_OUTPUT_DIR

apt-get install -yqq php8.2-xdebug
apt-get install -yqq php8.1-xdebug
apt-get install -yqq php8.0-xdebug
apt-get install -yqq php7.4-xdebug

DIR_LOG_PHP=/var/log/php/8.2
touch $DIR_LOG_PHP/xdebug.log
chmod 664 $DIR_LOG_PHP/xdebug.log
chgrp www-data $DIR_LOG_PHP/xdebug.log

echo 'xdebug.mode=debug,develop,coverage,trace,profile
; https://xdebug.org/docs/all_settings#start_with_request
xdebug.start_with_request = trigger
; https://xdebug.org/docs/all_settings#start_upon_error
xdebug.start_upon_error = no
xdebug.client_host=10.0.2.2
xdebug.client_port=9003
xdebug.dump.SERVER=REMOTE_ADDR,REQUEST_METHOD
xdebug.dump.GET=*
xdebug.max_nesting_level = 256
xdebug.cli_color=1
xdebug.collect_return=true
xdebug.output_dir='$DIR_XDEBUG_OUTPUT_DIR'
;xdebug.log='$DIR_LOG_PHP'/xdebug.log' >> /etc/php/8.2/mods-available/xdebug.ini

DIR_LOG_PHP=/var/log/php/8.1
touch $DIR_LOG_PHP/xdebug.log
chmod 664 $DIR_LOG_PHP/xdebug.log
chgrp www-data $DIR_LOG_PHP/xdebug.log

echo 'xdebug.mode=debug,develop,coverage,trace,profile
; https://xdebug.org/docs/all_settings#start_with_request
xdebug.start_with_request = trigger
; https://xdebug.org/docs/all_settings#start_upon_error
xdebug.start_upon_error = no
xdebug.client_host=10.0.2.2
xdebug.client_port=9003
xdebug.dump.SERVER=REMOTE_ADDR,REQUEST_METHOD
xdebug.dump.GET=*
xdebug.max_nesting_level = 256
xdebug.cli_color=1
xdebug.collect_return=true
xdebug.output_dir='$DIR_XDEBUG_OUTPUT_DIR'
;xdebug.log='$DIR_LOG_PHP'/xdebug.log' >> /etc/php/8.1/mods-available/xdebug.ini


DIR_LOG_PHP=/var/log/php/8.0
touch $DIR_LOG_PHP/xdebug.log
chmod 664 $DIR_LOG_PHP/xdebug.log
chgrp www-data $DIR_LOG_PHP/xdebug.log

echo 'xdebug.mode=debug,develop,coverage,trace,profile
; https://xdebug.org/docs/all_settings#start_with_request
xdebug.start_with_request = trigger
; https://xdebug.org/docs/all_settings#start_upon_error
xdebug.start_upon_error = no
xdebug.client_host=10.0.2.2
xdebug.client_port=9003
xdebug.dump.SERVER=REMOTE_ADDR,REQUEST_METHOD
xdebug.dump.GET=*
xdebug.max_nesting_level = 256
xdebug.cli_color=1
xdebug.collect_return=true
xdebug.output_dir='$DIR_XDEBUG_OUTPUT_DIR'
;xdebug.log='$DIR_LOG_PHP'/xdebug.log' >> /etc/php/8.0/mods-available/xdebug.ini

DIR_LOG_PHP=/var/log/php/7.4
touch $DIR_LOG_PHP/xdebug.log
chmod 664 $DIR_LOG_PHP/xdebug.log
chgrp www-data $DIR_LOG_PHP/xdebug.log

echo 'xdebug.mode=debug,develop,coverage,trace,profile
; https://xdebug.org/docs/all_settings#start_with_request
xdebug.start_with_request = trigger
; https://xdebug.org/docs/all_settings#start_upon_error
xdebug.start_upon_error = no
xdebug.client_host=10.0.2.2
xdebug.client_port=9003
xdebug.dump.SERVER=REMOTE_ADDR,REQUEST_METHOD
xdebug.dump.GET=*
xdebug.max_nesting_level = 256
xdebug.cli_color=1
xdebug.collect_return=true
xdebug.output_dir='$DIR_XDEBUG_OUTPUT_DIR'
;xdebug.log='$DIR_LOG_PHP'/xdebug.log' > /etc/php/7.4/mods-available/xdebug.ini


phpenmod -v ALL xdebug

exit 0