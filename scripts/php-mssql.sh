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

DEB_RELEASE=`cat /etc/debian_version | cut -d "." -f 1`

# https://www.microsoft.com/en-us/sql-server/developer-get-started/php/ubuntu?rtc=1
# https://docs.microsoft.com/de-de/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16
# https://github.com/microsoft/msphpsql/releases
# Download appropriate package for the OS version: Debian 11
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>&1
curl https://packages.microsoft.com/config/debian/$DEB_RELEASE/prod.list > /etc/apt/sources.list.d/mssql-release.list

apt-get -yqq update

# Install Driver 
ACCEPT_EULA=Y apt-get install -yq msodbcsql18
ACCEPT_EULA=Y apt-get install -yq msodbcsql17
# optional: for bcp and sqlcmd
ACCEPT_EULA=Y apt-get install -yq mssql-tools18
ACCEPT_EULA=Y apt-get install -yq mssql-tools

echo -e '\nexport PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
echo -e '\nexport PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# optional: for unixODBC development headers
apt-get -yq install unixodbc-dev

# optional: kerberos library for debian-slim distributions
apt-get -yq install libgssapi-krb5-2

# Fix PHP Notice in php7.4 with pecl: https://stackoverflow.com/questions/59720692/php-7-4-1-pear-1-10-10-is-not-working-trying-to-access-array-offset-on-value
mkdir -p /tmp/pear/cache

MSSQL_DRIVER_VERSION=5.10.1

yes '' | pecl -q -d php_suffix=8.2 -d preferred_state=beta install sqlsrv-$MSSQL_DRIVER_VERSION
yes '' | pecl -q -d php_suffix=8.2 -d preferred_state=beta install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

yes '' | pecl -q -d php_suffix=8.1 -d preferred_state=beta install sqlsrv-$MSSQL_DRIVER_VERSION
yes '' | pecl -q -d php_suffix=8.1 -d preferred_state=beta install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

yes '' | pecl -q -d php_suffix=8.0 install sqlsrv-$MSSQL_DRIVER_VERSION
yes '' | pecl -q -d php_suffix=8.0 install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

yes '' | pecl -q -d php_suffix=7.4 install sqlsrv-$MSSQL_DRIVER_VERSION
yes '' | pecl -q -d php_suffix=7.4 install pdo_sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r sqlsrv-$MSSQL_DRIVER_VERSION
pecl -q uninstall -r pdo_sqlsrv-$MSSQL_DRIVER_VERSION

echo '[mssql]
extension=sqlsrv.so
extension=pdo_sqlsrv.so' > /etc/php/8.2/mods-available/mssql.ini

echo '[mssql]
extension=sqlsrv.so
extension=pdo_sqlsrv.so' > /etc/php/8.1/mods-available/mssql.ini

echo '[mssql]
extension=sqlsrv.so
extension=pdo_sqlsrv.so' > /etc/php/8.0/mods-available/mssql.ini

echo '[mssql]
extension=sqlsrv.so
extension=pdo_sqlsrv.so' > /etc/php/7.4/mods-available/mssql.ini

phpenmod -v 8.2 mssql
phpenmod -v 8.1 mssql
phpenmod -v 8.0 mssql
phpenmod -v 7.4 mssql

exit 0