#!/bin/bash -eux
#title			: mailcatcher.sh
#description	: This script installs the mailcatcher
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2022-12-27
#notes			: replaced mailocal
echo ''
echo '==============================================================='
echo '===>                    Install Postfix                    <==='
echo '==============================================================='
echo ''
debconf-set-selections <<< "postfix postfix/mailname string default-lamp.local"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
apt-get install -yqq --assume-yes postfix
echo '* smtp:[localhost]:2525' > /etc/postfix/transport
postmap hash:/etc/postfix/transport
echo 'transport_maps = hash:/etc/postfix/transport' >> /etc/postfix/main.cf
apt-get install -yqq mailutils

echo ''
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '===>                  Install MailCatcher                  <==='
echo '==============================================================='
echo ''

#
apt-get install -yqq rubygems ruby-dev sqlite3 libsqlite3-dev

gem install net-imap -v 0.2.2
gem install net-protocol -v 0.1.2
gem install net-smtp -v 0.3.0
gem install mailcatcher

mv /tmp/files/systemd/mailcatcher.service /etc/systemd/system/mailcatcher.service
chown root:root /etc/systemd/system/mailcatcher.service
chmod 744 /etc/systemd/system/mailcatcher.service
systemctl enable mailcatcher.service

exit 0