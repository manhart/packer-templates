#!/bin/bash -eux
#title			: php-mssql.sh
#description	: This script will install the LAMP stack
#author			: Alexander Manhart <alexander@manhart-it.de>
#date			: 2021-04-03
#notes			: 

echo ''
echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
echo '===>          Install MSSQL Server PHP Extension           <==='
echo '==============================================================='
echo ''

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

# https://www.microsoft.com/en-us/sql-server/developer-get-started/php/ubuntu?rtc=1
# https://docs.microsoft.com/de-de/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16
# https://github.com/microsoft/msphpsql/releases
# Download appropriate package for the OS version:
DEB_RELEASE=`cat /etc/debian_version | cut -d "." -f 1`
curl https://packages.microsoft.com/config/debian/$DEB_RELEASE/prod.list > /etc/apt/sources.list.d/mssql-release.list

apt-get -yqq update

# Install Driver 
# we need old unixodbc 2.3.7 @issue: https://github.com/microsoft/msphpsql/issues/1438
# --allow-downgrades odbcinst=2.3.7 odbcinst1debian2=2.3.7 unixodbc-dev=2.3.7 unixodbc=2.3.7 
# --allow-downgrades odbcinst=2.3.7 odbcinst1debian2=2.3.7 unixodbc-dev=2.3.7 unixodbc=2.3.7 
ACCEPT_EULA=Y apt-get install -yq msodbcsql18 --no-install-recommends
# ACCEPT_EULA=Y apt-get install -yq msodbcsql17 --no-install-recommends
# optional: for bcp and sqlcmd
ACCEPT_EULA=Y apt-get install -yq mssql-tools18 --no-install-recommends
# ACCEPT_EULA=Y apt-get install -yq mssql-tools --no-install-recommends

echo -e '\nexport PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
echo -e '\nexport PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# optional: for unixODBC development headers
# --allow-downgrades unixodbc-dev=2.3.7 
apt-get -yq install unixodbc-dev --no-install-recommends

# optional: kerberos library for debian-slim distributions
apt-get -yq install libgssapi-krb5-2

# Fix PHP Notice in php7.4 with pecl: https://stackoverflow.com/questions/59720692/php-7-4-1-pear-1-10-10-is-not-working-trying-to-access-array-offset-on-value
mkdir -p /tmp/pear/cache

sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen

MSSQL_DRIVER_VERSION="5.12.0beta1"

wget -q https://pecl.php.net/get/sqlsrv-$MSSQL_DRIVER_VERSION.tgz -O /usr/src/sqlsrv-$MSSQL_DRIVER_VERSION.tgz
tar xzvf /usr/src/sqlsrv-$MSSQL_DRIVER_VERSION.tgz -C /usr/src
cd /usr/src/sqlsrv-$MSSQL_DRIVER_VERSION

echo 'mssql for php8.3'
/usr/bin/phpize8.3 --clean
/usr/bin/phpize8.3
./configure --silent --with-php-config=/usr/bin/php-config8.3 && make -s clean && make -s && make -s install

echo 'mssql for php8.2'
/usr/bin/phpize8.2 --clean
/usr/bin/phpize8.2
./configure --silent --with-php-config=/usr/bin/php-config8.2 && make -s clean && make -s && make -s install

echo 'mssql for php8.1'
/usr/bin/phpize8.1 --clean
/usr/bin/phpize8.1
./configure --silent --with-php-config=/usr/bin/php-config8.1 && make -s clean && make -s && make -s install

# yes '' | pecl -q -d php_suffix=8.3 -d preferred_state=beta install sqlsrv-$MSSQL_DRIVER_VERSION
# yes '' | pecl -q -d php_suffix=8.3 -d preferred_state=beta install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

# yes '' | pecl -q -d php_suffix=8.2 -d preferred_state=beta install sqlsrv-$MSSQL_DRIVER_VERSION
# yes '' | pecl -q -d php_suffix=8.2 -d preferred_state=beta install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

# yes '' | pecl -q -d php_suffix=8.1 install sqlsrv-$MSSQL_DRIVER_VERSION
# yes '' | pecl -q -d php_suffix=8.1 install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

# yes '' | pecl -q -d php_suffix=8.0 install sqlsrv-$MSSQL_DRIVER_VERSION
# yes '' | pecl -q -d php_suffix=8.0 install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

echo 'mssql for php7.4'
/usr/bin/phpize7.4 --clean
/usr/bin/phpize7.4
./configure --silent --with-php-config=/usr/bin/php-config7.4 && make -s clean && make -s && make -s install

wget -q https://pecl.php.net/get/pdo_sqlsrv-$MSSQL_DRIVER_VERSION.tgz -O /usr/src/pdo_sqlsrv-$MSSQL_DRIVER_VERSION.tgz
tar xzvf /usr/src/pdo_sqlsrv-$MSSQL_DRIVER_VERSION.tgz -C /usr/src
cd /usr/src/pdo_sqlsrv-$MSSQL_DRIVER_VERSION
/usr/bin/phpize8.3 --clean
/usr/bin/phpize8.3
./configure --silent --with-php-config=/usr/bin/php-config8.3 && make -s clean && make -s && make -s install

/usr/bin/phpize8.2 --clean
/usr/bin/phpize8.2
./configure --silent --with-php-config=/usr/bin/php-config8.2 && make -s clean && make -s && make -s install

/usr/bin/phpize8.1 --clean
/usr/bin/phpize8.1
./configure --silent --with-php-config=/usr/bin/php-config8.1 && make -s clean && make -s && make -s install

/usr/bin/phpize7.4 --clean
/usr/bin/phpize7.4
./configure --silent --with-php-config=/usr/bin/php-config7.4 && make -s clean && make -s && make -s install


# MSSQL_DRIVER_VERSION=5.10.1
# yes '' | pecl -q -d php_suffix=7.4 install sqlsrv-$MSSQL_DRIVER_VERSION
# yes '' | pecl -q -d php_suffix=7.4 install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
# pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

echo '; priority=20
extension=sqlsrv.so' > /etc/php/8.3/mods-available/sqlsrv.ini

echo '; priority=30
extension=pdo_sqlsrv.so' > /etc/php/8.3/mods-available/pdo_sqlsrv.ini

echo '; priority=20
extension=sqlsrv.so' > /etc/php/8.2/mods-available/sqlsrv.ini

echo '; priority=30
extension=pdo_sqlsrv.so' > /etc/php/8.2/mods-available/pdo_sqlsrv.ini

echo '; priority=20
extension=sqlsrv.so' > /etc/php/8.1/mods-available/sqlsrv.ini

echo '; priority=30
extension=pdo_sqlsrv.so' > /etc/php/8.1/mods-available/pdo_sqlsrv.ini

echo '; priority=20
extension=sqlsrv.so' > /etc/php/7.4/mods-available/sqlsrv.ini

echo '; priority=30
extension=pdo_sqlsrv.so' > /etc/php/7.4/mods-available/pdo_sqlsrv.ini

phpenmod -v 8.3 sqlsrv
phpenmod -v 8.3 pdo_sqlsrv
phpenmod -v 8.2 sqlsrv
phpenmod -v 8.2 pdo_sqlsrv
phpenmod -v 8.1 sqlsrv
phpenmod -v 8.1 pdo_sqlsrv
phpenmod -v 7.4 sqlsrv
phpenmod -v 7.4 pdo_sqlsrv

exit 0