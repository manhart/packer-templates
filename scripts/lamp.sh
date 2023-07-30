#!/bin/bash -eux
#title			: lamp.sh
#description	: This script will install the LAMP stack
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			: MariaDB 10.5.latest, PHP 7.4/8.0/8.1/8.2, Apache 2.4, Composer, Postfix, MailFetcher

echo ''
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '===>            Start installing the LAMP Stack            <==='
echo '==============================================================='
echo ''

# database configuration
DB_HOST='localhost'
DB_ROOT='root'
#DB_ROOT_PASS='$(openssl rand -hex 32)'
SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}
DB_USER=$SSH_USER
DB_USER_PASS=${SSH_PASSWORD:-vagrant}
VM_NAME=${VM_NAME}

# ensure database is installed
echo '===> Install MariaDB 10.5 <==='
apt-get install -y software-properties-common dirmngr apt-transport-https
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=10.5 --os-type=debian --os-version=bullseye

apt-get -yqq update
apt-get -yq install mariadb-server

# todo password for root! not necessary
# mysqladmin --user=root password "$DB_ROOT_PASS"

echo '[mysql]
default-character-set = utf8mb4

[mysqld]
default-storage-engine = aria

# we use a modern inndob fileformat:
innodb_file_format=Barracuda
innodb_large_prefix=on
innodb_log_file_size=64M
innodb_file_per_table=1

# Binary Logging
# we do not use replication (and for recovery it does not make sense to me either)
skip-log-bin 

# Logging
general_log_file = /var/log/mysql/general.log
log_error = /var/log/mysql/error.log

skip-networking=0
skip-bind-address

# we rather default to the full utf8 4-byte character set
character_set_server=utf8mb4
collation_server=utf8mb4_general_ci' > /etc/mysql/mariadb.conf.d/90-lamp.cnf

# Localhost
mysql -u$DB_ROOT -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_USER_PASS')"
mysql -u$DB_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION"

# Forwarded Ports
mysql -u$DB_ROOT -e "CREATE USER '$DB_USER'@'10.0.2.2' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_USER_PASS')"
mysql -u$DB_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'10.0.2.2' WITH GRANT OPTION"

# Host-Only network
mysql -u$DB_ROOT -e "CREATE USER '$DB_USER'@'192.168.56.%' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_USER_PASS')"
mysql -u$DB_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'192.168.56.%' WITH GRANT OPTION"

mysql -u$DB_ROOT -e "FLUSH PRIVILEGES"

# ensure apache is installed
echo '===> Install apache worker event <==='
apt-get -yq install apache2
apt-get -yq install apachetop

echo '===> Prepare Webserver Document_Root in /srv/www <==='
mkdir -p /srv/www
chgrp www-data /srv/www
chmod 2775 /srv/www
ln -nfs /srv/www /virtualweb

a2dissite 000-default.conf

# Configure Apache
# forces flush only for special filter/files: ProxyPassMatch "^/masterDeployer/deploy\.php(/.*)?$" "unix:/run/php/php7.4-fpm.sock|fcgi://localhost/srv/www/" enablereuse=on flushpackets=on
echo '===> Configure Apache default vhost <==='
echo '<VirtualHost *:80>
	DocumentRoot /srv/www
	AllowEncodedSlashes On
	# we deactivate sendfile for faster static content delivery, because it (pagecache) can make problems with nfs, smb, ... shares
	EnableSendfile Off
	# disabling HSTS will allow your site to be publicly viewed over HTTP and/or insecure HTTPS connection
	Header unset Strict-Transport-Security
	Header always set Strict-Transport-Security "max-age=0;includeSubDomains"
	# activate HTTP/2 protocol
	Protocols h2 h2c http/1.1
	<Directory /srv/www>
		Options Indexes FollowSymLinks
		DirectoryIndex index.php index.html
		AllowOverride All
		Require all granted
	</Directory>
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/default-lamp.conf

a2enmod headers
a2enmod http2
a2ensite default-lamp.conf

echo '===> Configure Apache default ssl vhost: '$VM_NAME' <==='
# SSL/TLS self-signed certificate
if [[ ! -d $SSH_USER_HOME/ssl ]]
then
	mkdir -p $SSH_USER_HOME/ssl
	chown $SSH_USER $SSH_USER_HOME/ssl
fi
if [[ ! -f $SSH_USER_HOME/ssl/$VM_NAME.local.key ]]
then
	openssl genrsa -out $SSH_USER_HOME/ssl/$VM_NAME.local.key 4096
	chgrp ssl-cert $SSH_USER_HOME/ssl/$VM_NAME.local.key
	chown $SSH_USER $SSH_USER_HOME/ssl/$VM_NAME.local.key
	openssl req -new -x509 -key $SSH_USER_HOME/ssl/$VM_NAME.local.key -out $SSH_USER_HOME/ssl/$VM_NAME.local.crt -days 3650 -subj /CN=$VM_NAME.local
	chown $SSH_USER $SSH_USER_HOME/ssl/$VM_NAME.local.crt
fi

echo '<IfModule mod_ssl.c>
	<VirtualHost *:443>
		DocumentRoot /srv/www
		AllowEncodedSlashes On
		# we deactivate sendfile for faster static content delivery, because it (pagecache) can make problems with nfs, smb, ... shares
		EnableSendfile Off
		# activate HTTP/2 protocol
		Protocols h2 h2c http/1.1
		SSLEngine on
		SSLCertificateFile '$SSH_USER_HOME'/ssl/'$VM_NAME'.local.crt
		SSLCertificateKeyFile '$SSH_USER_HOME'/ssl/'$VM_NAME'.local.key
		<Directory /srv/www>
			Options Indexes FollowSymLinks
			DirectoryIndex index.php index.html
			AllowOverride All
			Require all granted
		</Directory>
		<FilesMatch "\.(cgi|shtml|phtml|php)$">
			SSLOptions +StdEnvVars
		</FilesMatch>
		<Directory /usr/lib/cgi-bin>
			SSLOptions +StdEnvVars
		</Directory>
		ErrorLog ${APACHE_LOG_DIR}/error.log
		CustomLog ${APACHE_LOG_DIR}/access.log combined
	</VirtualHost>
</IfModule>' > /etc/apache2/sites-available/default-ssl-lamp.conf

echo '<IfModule !mod_php7.c>
<IfModule proxy_fcgi_module>
    # flushpackets forces the module to flush every chunk of data received from the FCGI backend as soon as it receives it, without buffering
    <Proxy "fcgi://localhost/" flushpackets=on>
    </Proxy>
</IfModule>
</IfModule>' > /etc/apache2/conf-available/proxy.conf

a2enconf proxy
a2enmod ssl
a2ensite default-ssl-lamp.conf

usermod -a -G www-data vagrant

echo ''
echo '==============================================================='
echo '===>     Prepare installing PHP 7.4/8.0/8.1/8.2    <==='
echo '==============================================================='
echo ''

apt-get install -yq memcached

apt-get install -yq redis-server

wget https://packages.sury.org/php/apt.gpg
apt-key add apt.gpg
rm -f apt.gpg

echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
apt-get -y update

echo '===> Install PHP 7.4 <==='
apt-get install -yq php7.4-fpm php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-odbc php7.4-ldap php7.4-dev php7.4-gd php7.4-sqlite3 php7.4-bcmath php7.4-geoip php7.4-imap php7.4-mailparse php7.4-soap --allow-unauthenticated

echo '===> Install PHP 8.0 <==='
apt-get install -yq php8.0-fpm php8.0-cli php8.0-common php8.0-opcache php8.0-odbc php8.0-ldap php8.0-dev php8.0-gd php8.0-sqlite3 php8.0-bcmath php8.0-imap php8.0-mailparse php8.0-soap --allow-unauthenticated

echo '===> Install PHP 8.1 <==='
apt-get install -yq php8.1-fpm php8.1-cli php8.1-common php8.1-opcache php8.1-odbc php8.1-ldap php8.1-dev php8.1-gd php8.1-sqlite3 php8.1-bcmath php8.1-imap php8.1-mailparse php8.1-soap --allow-unauthenticated

echo '===> Install PHP 8.2 <==='
apt-get install -yq php8.2-fpm php8.2-cli php8.2-common php8.2-opcache php8.2-odbc php8.2-ldap php8.2-dev php8.2-gd php8.2-sqlite3 php8.2-bcmath php8.2-imap php8.2-mailparse php8.2-soap --allow-unauthenticated

# php8.0-geoip not availaible

# default PHP Version should be the last installed
# echo '===> set default PHP Version 7.4 <==='
# update-alternatives --set php /usr/bin/php7.4
# update-alternatives --set phpize /usr/bin/phpize7.4
# update-alternatives --set php-config /usr/bin/php-config7.4

# apt-get install -yq php-memcached 02.03.2021, AM, doesn't work anymore

apt-get install -yq php-mysql php-curl php-mbstring php-intl php-xml php-yaml php-memcached php-redis php-zip php-imagick
apt-get install -yq php-maxminddb

# Log directories
echo ''
echo '==============================================================='
echo '===>               Create PHP Log directories              <==='
echo '==============================================================='
echo ''
DIR_LOG_PHP=/var/log/php/8.2
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP

DIR_LOG_PHP=/var/log/php/8.1
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP

DIR_LOG_PHP=/var/log/php/8.0
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP

DIR_LOG_PHP=/var/log/php/7.4
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP


echo ''
echo '==============================================================='
echo '===>               Modify settings in php.ini              <==='
echo '==============================================================='
echo '' 
sed -i 's#^error_log = /var/log/php8\.2-fpm\.log$#error_log = /var/log/php/8.2/php-fpm.log#g' /etc/php/8.2/fpm/php-fpm.conf
sed -i 's#^error_log = /var/log/php8\.1-fpm\.log$#error_log = /var/log/php/8.1/php-fpm.log#g' /etc/php/8.1/fpm/php-fpm.conf
sed -i 's#^error_log = /var/log/php8\.0-fpm\.log$#error_log = /var/log/php/8.0/php-fpm.log#g' /etc/php/8.0/fpm/php-fpm.conf
sed -i 's#^error_log = /var/log/php/7\.4-fpm\.log$#error_log = /var/log/php/7.4/php-fpm.log#g' /etc/php/7.4/fpm/php-fpm.conf

sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/8.0/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/7.4/fpm/php.ini

sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.2/fpm/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.1/fpm/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.0/fpm/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/7.4/fpm/php.ini

sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.2/fpm/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.1/fpm/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.0/fpm/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/7.4/fpm/php.ini

sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.2/cli/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.1/cli/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.0/cli/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/7.4/cli/php.ini

sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.2/cli/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.1/cli/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.0/cli/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/7.4/cli/php.ini

sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.2/fpm/php.ini
sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.1/fpm/php.ini
sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.0/fpm/php.ini
sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/7.4/fpm/php.ini

sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/8.0/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/7.4/fpm/php.ini

sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/8.0/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/7.4/fpm/php.ini

sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/8.2/fpm/php.ini
sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/8.1/fpm/php.ini
sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/8.0/fpm/php.ini
sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/7.4/fpm/php.ini

sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.2/php_errors\.log#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.1/php_errors\.log#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.0/php_errors\.log#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/7\.4/php_errors\.log#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.2/php_errors\.log#' /etc/php/8.2/cli/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.1/php_errors\.log#' /etc/php/8.1/cli/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.0/php_errors\.log#' /etc/php/8.0/cli/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/7\.4/php_errors\.log#' /etc/php/7.4/cli/php.ini

sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;max_input_vars = .*$#max_input_vars = 2000#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;max_input_vars = .*$#max_input_vars = 2000#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;max_input_vars = .*$#max_input_vars = 2000#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;max_input_vars = .*$#max_input_vars = 2000#' /etc/php/7.4/fpm/php.ini

sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/8.2/fpm/php.ini
sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/8.1/fpm/php.ini
sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/8.0/fpm/php.ini
sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/8.2/fpm/php.ini
sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/8.1/fpm/php.ini
sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/8.0/fpm/php.ini
sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/7.4/fpm/php.ini

# https://github.com/php-memcached-dev/php-memcached/issues/310
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = Off#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = Off#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = Off#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = Off#' /etc/php/7.4/fpm/php.ini

# enable building of phar files
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/8.0/fpm/php.ini
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/7.4/fpm/php.ini

# https://ma.ttias.be/php-session-locking-prevent-sessions-blocking-in-requests/
echo 'memcached.sess_locking = Off' >> /etc/php/8.2/fpm/conf.d/25-memcached.ini
echo 'memcached.sess_locking = Off' >> /etc/php/8.1/fpm/conf.d/25-memcached.ini
echo 'memcached.sess_locking = Off' >> /etc/php/8.0/fpm/conf.d/25-memcached.ini
echo 'memcached.sess_locking = Off' >> /etc/php/7.4/fpm/conf.d/25-memcached.ini

# deactivate opcache in dev (e.g. problems with deprecated error messages. it compiles php code)
echo 'opcache.enable=0' >> /etc/php/8.2/mods-available/opcache.ini
echo 'opcache.enable=0' >> /etc/php/8.1/mods-available/opcache.ini
echo 'opcache.enable=0' >> /etc/php/8.0/mods-available/opcache.ini
echo 'opcache.enable=0' >> /etc/php/7.4/mods-available/opcache.ini

# php runs as vagrant (for deployer and the windows share)
sed -i 's/^user = .*$/user = vagrant/' /etc/php/8.2/fpm/pool.d/www.conf
sed -i 's/^user = .*$/user = vagrant/' /etc/php/8.1/fpm/pool.d/www.conf
sed -i 's/^user = .*$/user = vagrant/' /etc/php/8.0/fpm/pool.d/www.conf
sed -i 's/^user = .*$/user = vagrant/' /etc/php/7.4/fpm/pool.d/www.conf

echo ''
echo '==============================================================='
echo '===>            enabling PHP 8.2 FPM by default            <==='
echo '==============================================================='
echo ''
a2enmod proxy_fcgi setenvif
a2enconf php8.2-fpm

echo ''
echo '==============================================================='
echo '===>                    Install Composer 2                 <==='
echo '==============================================================='
echo ''
export COMPOSER_DISABLE_XDEBUG_WARN=1
# Installing Composer latest version

curl -sS https://getcomposer.org/installer | sudo /usr/bin/php8.2 -- --install-dir=/usr/local/bin --filename=composer
chgrp vagrant /usr/local/bin/composer
chmod 775 /usr/local/bin/composer


# Fix permissions
#mkdir -p /home/vagrant/.cache/composer
#chown -R vagrant.vagrant /home/vagrant/.cache
#mkdir -p /home/vagrant/.config
#chown -R vagrant.vagrant /home/vagrant/.config
#mkdir -p /home/vagrant/.local
#chown -R vagrant.vagrant /home/vagrant/.local
#chown vagrant /usr/local/bin/composer

echo ''
echo '==============================================================='
echo '===>                    Install PHPUnit9                   <==='
echo '==============================================================='
echo ''
# Installing PHPUnit 9 (compatible with PHP >7.0)

wget -nv -O phpunit https://phar.phpunit.de/phpunit-9.phar
mv phpunit /usr/local/bin/
chmod +x /usr/local/bin/phpunit
# chown vagrant /usr/local/bin/phpunit

# echo ''
# echo '==============================================================='
# echo '===>                     Patching PEAR                     <==='
# echo '==============================================================='
# echo ''
# Patch PEAR (xdebug causes E_Notice messages)
# patch /usr/share/php/PEAR/REST.php /tmp/files/patch/PEAR/REST.patch

echo ''
echo '==============================================================='
echo '===>                     Install Deployer                  <==='
echo '==============================================================='
echo ''
curl -LO https://deployer.org/releases/v6.9.0/deployer.phar
mv deployer.phar /usr/local/bin/dep
chgrp vagrant /usr/local/bin/dep
chmod 775 /usr/local/bin/dep
dep autocomplete --install | sudo tee /etc/bash_completion.d/deployer 1>/dev/null
# https://github.com/deployphp/recipes
mkdir -p /usr/share/php/recipe
wget -O /usr/share/php/recipe/ms-teams.php https://raw.githubusercontent.com/deployphp/recipes/master/recipe/ms-teams.php


echo ''
echo '==============================================================='
echo '===>                       nodejs v19                      <==='
echo '==============================================================='
echo ''

apt-get install -yqq curl software-properties-common

curl -fsSL https://deb.nodesource.com/setup_19.x | bash -

apt-get install -yqq nodejs

echo ''
echo '==============================================================='
echo '===>                   sass, uglify-js                     <==='
echo '==============================================================='
echo ''

npm install --quiet -g sass
npm install --quiet -g uglify-js


echo ''
echo '==============================================================='
echo '===>                        pdfunite                       <==='
echo '==============================================================='
echo ''
apt-get install -yqq poppler-utils

exit 0