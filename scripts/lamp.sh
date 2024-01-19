#!/bin/bash -eux
#title			: lamp.sh
#description	: This script will install the LAMP stack
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2020-05-27
#notes			: MariaDB 10.11.latest, PHP 7.4/8.1/8.2/8.3 Apache 2.4, Composer, Postfix, MailFetcher

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
HOME_DIR=${HOME_DIR:-/home/${SSH_USER}}
DB_USER=$SSH_USER
DB_USER_PASS=${SSH_PASSWORD:-vagrant}
VM_NAME=${VM_NAME}

# ensure database is installed
echo '===> Install MariaDB 10.11 <==='
apt-get install -y software-properties-common dirmngr apt-transport-https
curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=10.11

apt-get -yqq update
apt-get -yq install mariadb-server

# todo password for root! not necessary
# mysqladmin --user=root password "$DB_ROOT_PASS"

echo '[mysql]
default-character-set = utf8mb4

[mysqld]
default-storage-engine = aria

table_definition_cache = 768
innodb_stats_on_metadata=off
innodb_file_per_table=on
# InnoDB buffer pool size can be set up to 80% of the total memory
innodb_buffer_pool_size=2G
# 25% of innodb_buffer_pool_size
innodb_log_file_size=512M

#Performance schema
performance_schema = on

# we do not use name resolving
skip-name-resolve=on

# Logging
general_log_file = /var/log/mysql/general.log
log_error = /var/log/mysql/error.log

skip-networking=0
skip-bind-address

# we rather default to the full utf8 4-byte character set
character_set_server=utf8mb4
collation_server=utf8mb4_general_ci' > /etc/mysql/mariadb.conf.d/90-lamp.cnf

# Localhost
mysql -u$DB_ROOT -e "CREATE USER '$DB_USER'@'127.0.0.1' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_USER_PASS')"
mysql -u$DB_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'127.0.0.1' WITH GRANT OPTION"

# over unix socket without password
mysql -u$DB_ROOT -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED VIA unix_socket"
mysql -u$DB_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'localhost' WITH GRANT OPTION"

# Forwarded Ports
mysql -u$DB_ROOT -e "CREATE USER '$DB_USER'@'10.0.2.2' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_USER_PASS')"
mysql -u$DB_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'10.0.2.2' WITH GRANT OPTION"

# Host-Only network
mysql -u$DB_ROOT -e "CREATE USER '$DB_USER'@'192.168.56.%' IDENTIFIED VIA mysql_native_password USING PASSWORD('$DB_USER_PASS')"
mysql -u$DB_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'192.168.56.%' WITH GRANT OPTION"

mysql -u$DB_ROOT -e "FLUSH PRIVILEGES"

echo ''
echo '==============================================================='
echo '===>                        MySQLTuner                     <==='
echo '==============================================================='
echo 'from https://github.com/major/MySQLTuner-perl'
echo ''
wget -q https://raw.githubusercontent.com/major/MySQLTuner-perl/v2.2.12/mysqltuner.pl -O /opt/scripts/mysqltuner.pl

if [ "1c2cf8d189f0e35a9e0d8da3e5b13a7896e6007b9f2b2bd6475624148f91c100" != $(sha256sum /opt/scripts/mysqltuner.pl | awk '{print $1}') ]; then
  rm /opt/scripts/mysqltuner.pl
  echo "MySQL Tuner Checksum is invalid"
else
  chmod ugo+x /opt/scripts/mysqltuner.pl
  wget -q https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O /opt/scripts/basic_passwords.txt
  wget -q https://raw.githubusercontent.com/major/MySQLTuner-perl/master/vulnerabilities.csv -O /opt/scripts/vulnerabilities.csv
  echo 'MySQLTuner installed'
fi

# ensure apache is installed
echo ''
echo '==============================================================='
echo '===>     Prepare installing Apache 2.4                     <==='
echo '==============================================================='
echo ''

usermod -a -G www-data vagrant
echo '===> Install apache worker event <==='
apt-get -yq install apache2
apt-get -yq install apachetop libapache2-mod-auth-openidc

echo '===> Prepare Webserver Document_Root in /virtualweb <==='
mkdir -p /srv/www
chgrp www-data /srv/www
chmod 2775 /srv/www
ln -nfs /srv/www /virtualweb

a2dissite 000-default.conf

echo '<IfModule proxy_fcgi_module>
    # flushpackets forces the module to flush every chunk of data received from the FCGI backend as soon as it receives it, without buffering
    <Proxy "fcgi://localhost/" flushpackets=on>
    </Proxy>
</IfModule>' > /etc/apache2/conf-available/proxy.conf

a2enmod headers
a2enmod http2
a2enmod ssl
a2enconf proxy

# Configure Apache with default VHost
# forces flush only for special filter/files: ProxyPassMatch "^/masterDeployer/deploy\.php(/.*)?$" "unix:/run/php/php7.4-fpm.sock|fcgi://localhost/srv/www/" enablereuse=on flushpackets=on

echo ''
echo '==============================================================='
echo '===>     Prepare installing PHP 7.4/8.1/8.2/8.3        <==='
echo '==============================================================='
echo ''

apt-get install -yq memcached

apt-get install -yq redis-server

wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
apt-get -y update

echo '===> Install PHP 7.4 <==='
apt-get install -yq php7.4-fpm php7.4-cli php7.4-common php7.4-opcache php7.4-odbc php7.4-ldap php7.4-dev php7.4-gd php7.4-sqlite3 php7.4-bcmath php7.4-imap php7.4-soap php7.4-mysql php7.4-curl php7.4-xml php7.4-intl php7.4-mbstring php7.4-zip php7.4-gd php7.4-maxminddb php7.4-yaml php7.4-redis php7.4-imagick php7.4-mailparse php7.4-memcached php7.4-json php7.4-geoip --allow-unauthenticated

echo '===> Install PHP 8.1 <==='
apt-get install -yq php8.1-fpm php8.1-cli php8.1-common php8.1-opcache php8.1-odbc php8.1-ldap php8.1-dev php8.1-gd php8.1-sqlite3 php8.1-bcmath php8.1-imap php8.1-soap php8.1-mysql php8.1-curl php8.1-xml php8.1-intl php8.1-mbstring php8.1-zip php8.1-gd php8.1-maxminddb php8.1-yaml php8.1-redis php8.1-imagick php8.1-mailparse php8.1-memcached --allow-unauthenticated

echo '===> Install PHP 8.2 <==='
apt-get install -yq php8.2-fpm php8.2-cli php8.2-common php8.2-opcache php8.2-odbc php8.2-ldap php8.2-dev php8.2-gd php8.2-sqlite3 php8.2-bcmath php8.2-imap php8.2-soap php8.2-mysql php8.2-curl php8.2-xml php8.2-intl php8.2-mbstring php8.2-zip php8.2-gd php8.2-maxminddb php8.2-yaml php8.2-redis php8.2-imagick php8.2-mailparse php8.2-memcached --allow-unauthenticated

echo '===> Install PHP 8.3 <==='
apt-get install -yq php8.3-fpm php8.3-cli php8.3-common php8.3-{bcmath,gd,imap,ldap,soap,mysql,curl,intl,imagick,igbinary,mailparse,maxminddb,mbstring,memcached,msgpack,odbc,opcache,redis,sqlite3,xdebug,xml,yaml,zip} --allow-unauthenticated

# default PHP Version should be the last installed
# echo '===> set default PHP Version 7.4 <==='
# update-alternatives --set php /usr/bin/php7.4
# update-alternatives --set phpize /usr/bin/phpize7.4
# update-alternatives --set php-config /usr/bin/php-config7.4

apt-get install -yq php-maxminddb php-gd php-imagick



# pecl -q -d php_suffix=8.3 -d preferred_state=stable install mailparse-3.1.6 not working because of https://stackoverflow.com/questions/35793216/installing-mailparse-php7-mbstring-error/36636332#36636332


# Log directories
echo ''
echo '==============================================================='
echo '===>               Create PHP Log directories              <==='
echo '==============================================================='
echo ''
DIR_LOG_PHP=/var/log/php/8.3
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP

DIR_LOG_PHP=/var/log/php/8.2
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP

DIR_LOG_PHP=/var/log/php/8.1
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP

DIR_LOG_PHP=/var/log/php/7.4
mkdir -p $DIR_LOG_PHP
chgrp www-data $DIR_LOG_PHP
chmod 775 $DIR_LOG_PHP
echo 'Done'

echo ''
echo '==============================================================='
echo '===>               Modify settings in php.ini              <==='
echo '==============================================================='
echo '' 
sed -i 's#^error_log = /var/log/php8\.3-fpm\.log$#error_log = /var/log/php/8.3/php-fpm.log#g' /etc/php/8.3/fpm/php-fpm.conf
sed -i 's#^error_log = /var/log/php8\.2-fpm\.log$#error_log = /var/log/php/8.2/php-fpm.log#g' /etc/php/8.2/fpm/php-fpm.conf
sed -i 's#^error_log = /var/log/php8\.1-fpm\.log$#error_log = /var/log/php/8.1/php-fpm.log#g' /etc/php/8.1/fpm/php-fpm.conf
sed -i 's#^error_log = /var/log/php/7\.4-fpm\.log$#error_log = /var/log/php/7.4/php-fpm.log#g' /etc/php/7.4/fpm/php-fpm.conf

sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/8.3/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^memory_limit = .*$/memory_limit = 256M/' /etc/php/7.4/fpm/php.ini

sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.3/fpm/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.2/fpm/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/8.1/fpm/php.ini
sed -i 's/^display_errors = .*$/display_errors = On/' /etc/php/7.4/fpm/php.ini

sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.3/fpm/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.2/fpm/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/8.1/fpm/php.ini
sed -i 's/^display_startup_errors = .*$/display_startup_errors = On/' /etc/php/7.4/fpm/php.ini

sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.3/fpm/php.ini
sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.2/fpm/php.ini
sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/8.1/fpm/php.ini
sed -i 's/^error_reporting = .*$/error_reporting = E_ALL/' /etc/php/7.4/fpm/php.ini

sed -i 's/^zend.assertions = .*$/zend.assertions = 1/' /etc/php/8.3/fpm/php.ini
sed -i 's/^zend.assertions = .*$/zend.assertions = 1/' /etc/php/8.2/fpm/php.ini
sed -i 's/^zend.assertions = .*$/zend.assertions = 1/' /etc/php/8.1/fpm/php.ini
sed -i 's/^zend.assertions = .*$/zend.assertions = 1/' /etc/php/7.4/fpm/php.ini

sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/8.3/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^upload_max_filesize = .*$/upload_max_filesize = 32M/' /etc/php/7.4/fpm/php.ini

sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/8.3/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/8.2/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/8.1/fpm/php.ini
sed -i 's/^post_max_size = .*$/post_max_size = 32M/' /etc/php/7.4/fpm/php.ini

sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/8.3/fpm/php.ini
sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/8.2/fpm/php.ini
sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/8.1/fpm/php.ini
sed -i 's/^max_file_uploads = .*$/max_file_uploads = 30/' /etc/php/7.4/fpm/php.ini

sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.3/php_errors\.log#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.2/php_errors\.log#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/8\.1/php_errors\.log#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;error_log = php_errors.log$#error_log = /var/log/php/7\.4/php_errors\.log#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;date.timezone =.*$#date.timezone = "Europe/Berlin"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;date.default_latitude =.*$#date.default_latitude = "52.5194"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;date.default_longitude =.*$#date.default_longitude = "13.4067"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;max_input_vars = .*$#max_input_vars = 1000#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;max_input_vars = .*$#max_input_vars = 1000#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;max_input_vars = .*$#max_input_vars = 1000#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;max_input_vars = .*$#max_input_vars = 1000#' /etc/php/7.4/fpm/php.ini

sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/8.3/fpm/php.ini
sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/8.2/fpm/php.ini
sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/8.1/fpm/php.ini
sed -i 's#^session.save_handler = files$#session.save_handler = memcached#' /etc/php/7.4/fpm/php.ini

sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;session.save_path = .*$#session.save_path = "localhost:11211"#' /etc/php/7.4/fpm/php.ini

sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/8.3/fpm/php.ini
sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/8.2/fpm/php.ini
sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/8.1/fpm/php.ini
sed -i 's#^session.gc_maxlifetime = .*$#session.gc_maxlifetime = 14400#' /etc/php/7.4/fpm/php.ini

# https://github.com/php-memcached-dev/php-memcached/issues/310
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = On#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = On#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = Off#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;session.lazy_write = .*$#session.lazy_write = Off#' /etc/php/7.4/fpm/php.ini

# enable building of phar files
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/8.3/fpm/php.ini
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/8.2/fpm/php.ini
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/8.1/fpm/php.ini
sed -i 's#^;phar.readonly = .*$#phar.readonly = Off#' /etc/php/7.4/fpm/php.ini

# https://ma.ttias.be/php-session-locking-prevent-sessions-blocking-in-requests/
echo 'memcached.sess_locking = Off' >> /etc/php/8.3/mods-available/memcached.ini
echo 'memcached.sess_locking = Off' >> /etc/php/8.2/mods-available/memcached.ini
echo 'memcached.sess_locking = Off' >> /etc/php/8.1/mods-available/memcached.ini
echo 'memcached.sess_locking = Off' >> /etc/php/7.4/mods-available/memcached.ini

# deactivate jit compiler in dev (e.g. problems with deprecated error messages. it compiles php code)
echo 'opcache.jit=off' >> /etc/php/8.3/mods-available/opcache.ini
echo 'opcache.jit=off' >> /etc/php/8.2/mods-available/opcache.ini
echo 'opcache.jit=off' >> /etc/php/8.1/mods-available/opcache.ini
echo 'opcache.jit=off' >> /etc/php/7.4/mods-available/opcache.ini

# activate opcache (e.g. problems with deprecated error messages. it compiles php code)
echo 'opcache.enable=1
opcache.memory_consumption=192
opcache.max_wasted_percentage=10
opcache.interned_strings_buffer=16' >> /etc/php/8.3/mods-available/opcache.ini
echo 'opcache.enable=1
opcache.memory_consumption=192
opcache.max_wasted_percentage=10
opcache.interned_strings_buffer=16' >> /etc/php/8.2/mods-available/opcache.ini
echo 'opcache.enable=1' >> /etc/php/8.1/mods-available/opcache.ini
echo 'opcache.enable=1' >> /etc/php/7.4/mods-available/opcache.ini

# php runs as vagrant (for deployer and the windows share)
sed -i 's/^user = .*$/user = vagrant/' /etc/php/8.3/fpm/pool.d/www.conf
sed -i 's/^user = .*$/user = vagrant/' /etc/php/8.2/fpm/pool.d/www.conf
sed -i 's/^user = .*$/user = vagrant/' /etc/php/8.1/fpm/pool.d/www.conf
sed -i 's/^user = .*$/user = vagrant/' /etc/php/7.4/fpm/pool.d/www.conf
echo 'Done'

#echo ''
#echo '==============================================================='
#echo '===>            Enabling PHP 8.2 FPM by default            <==='
#echo '==============================================================='
#echo ''
a2enmod proxy_fcgi setenvif
#a2enconf php8.2-fpm
#update-alternatives --set php /usr/bin/php8.2
#update-alternatives --set phpize /usr/bin/phpize8.2
#update-alternatives --set php-config /usr/bin/php-config8.2

echo ''
echo '==============================================================='
echo '===>                    Install Composer 2                 <==='
echo '==============================================================='
echo ''
export COMPOSER_DISABLE_XDEBUG_WARN=1
# Installing Composer latest version

curl -sS https://getcomposer.org/installer | /usr/bin/php -- --install-dir=/usr/local/bin --filename=composer
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
echo '===>                    Install PHPUnit10                  <==='
echo '==============================================================='
echo ''
# Installing PHPUnit 10 (compatible with PHP >7.0)

wget -nv -O phpunit https://phar.phpunit.de/phpunit-10.phar
mv phpunit /usr/local/bin/
chmod +x /usr/local/bin/phpunit
# chown vagrant /usr/local/bin/phpunit

echo ''
echo '==============================================================='
echo '===>                     Install Deployer                  <==='
echo '==============================================================='
echo ''
curl -LO https://github.com/deployphp/deployer/releases/download/v7.3.1/deployer.phar
mv deployer.phar /usr/local/bin/dep
chgrp vagrant /usr/local/bin/dep
chmod 775 /usr/local/bin/dep
# Still not working: https://github.com/deployphp/deployer/issues/3366
dep completion bash > /etc/bash_completion.d/deployer


echo ''
echo '==============================================================='
echo '===>                       nodejs v20                      <==='
echo '==============================================================='
echo ''

apt-get install -yqq curl

mkdir -p /etc/apt/keyrings/
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
apt-get update && apt-get install nodejs -yqq

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