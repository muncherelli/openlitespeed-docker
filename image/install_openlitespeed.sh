#!/bin/bash

mkdir -p /tmp/openlitespeed-release && \
wget -qO- https://github.com/litespeedtech/openlitespeed/releases/download/v${OPENLITESPEED_VERSION}/openlitespeed-${OPENLITESPEED_VERSION}-$(uname -m)-linux.tgz | tar xvz -C /tmp/openlitespeed-release --strip-components=1 && \
if [[ $PHP_VERSION != 7* ]]; then sed -i "s/^USE_LSPHP7=.*/USE_LSPHP7=no/" /tmp/openlitespeed-release/ols.conf; fi && \
sed -i "s/^LSPHPVER=.*/LSPHPVER=${PHP_VERSION//./}/" /tmp/openlitespeed-release/_in.sh && \
cd /tmp/openlitespeed-release && \
./install.sh && \
rm -rf /tmp/openlitespeed-release
rm -rf /usr/local/lsws/conf/templates/*

chown 999:999 /usr/local/lsws/conf -R && \
mkdir -p /var/www/vhosts/localhost/public && \
chown 1000:1000 /var/www/vhosts/localhost/ -R && \
rm -rf /usr/local/lsws/Example && \
cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/ && \
cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/
