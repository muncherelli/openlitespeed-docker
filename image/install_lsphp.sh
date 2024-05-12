#!/bin/bash

curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

apt-get update
DEBIAN_FRONTEND=noninteractive ACCEPT_EULA=Y apt-get install -y msodbcsql18
DEBIAN_FRONTEND=noninteractive ACCEPT_EULA=Y apt-get install -y mssql-tools18
DEBIAN_FRONTEND=noninteractive apt-get install -y unixodbc-dev

# install litespeed repository
wget -O - https://repo.litespeed.sh | bash

# install mysql client
DEBIAN_FRONTEND=noninteractive apt-get install -y default-mysql-client

# install unixodbc for sqlsrv
DEBIAN_FRONTEND=noninteractive apt-get install unixodbc-dev

# install lsphp83
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    lsphp83 lsphp83-common \
    lsphp83-curl \
    lsphp83-dbg \
    lsphp83-dev \
    lsphp83-imap \
    lsphp83-intl \
    lsphp83-ldap \
    lsphp83-mysql \
    lsphp83-opcache \
    lsphp83-pear \
    lsphp83-pgsql \
    lsphp83-pspell \
    lsphp83-snmp \
    lsphp83-sybase \
    lsphp83-sqlite3 \
    lsphp83-tidy

/usr/local/lsws/lsphp83/bin/pecl install redis
echo "extension=redis.so" | tee -a /usr/local/lsws/lsphp83/etc/php/8.3/litespeed/php.ini > /dev/null

/usr/local/lsws/lsphp83/bin/pecl install pdo_sqlsrv
echo "extension=pdo_sqlsrv.so" | tee -a /usr/local/lsws/lsphp83/etc/php/8.3/litespeed/php.ini > /dev/null

/usr/local/lsws/lsphp83/bin/pecl install sqlsrv
echo "extension=sqlsrv.so" | tee -a /usr/local/lsws/lsphp83/etc/php/8.3/litespeed/php.ini > /dev/null
