FROM docker.io/debian:bullseye-slim
ARG OPENLITESPEED_VERSION=1.7.17
ARG PHP_VERSION=8.2
ARG PHP_MODULES=curl intl imagick imap json mysql opcache pgsql sqlite3 redis

# Use bash shell
SHELL ["/bin/bash", "-c"]

##
# Install Openlitespeed:
# - Install necessary system dependencies
# - Install architecture-specific dependencies
# - Download and extract openlitespeed release from the specified URL
# - Adjust openlitespeed installer configuration for PHP version
# - Install openlitespeed
# - Remove openlitespeed release files from /tmp
# - Write 'cloud-docker' to /usr/local/lsws/PLAT
#
# Set Up LiteSpeed Repository and Install PHP Modules:
# - Download and save GPG keys for LiteSpeed repositories
# - Add LiteSpeed repositories to the sources list
# - Remove 'json' from PHP_MODULES if PHP version isn't 7.x
# - Install the required PHP version and its common modules
# - Install additional PHP modules specified in $PHP_MODULES
# - Clean apt cache and remove temporary files
#
# Download and Set Up lsup.sh Script:
# - Download lsup.sh script from GitHub and save it to /usr/local/lsws/admin/misc
# - Make the downloaded script executable
##
RUN if [[ $PHP_VERSION != 7* ]]; then PHP_MODULES=$(echo $PHP_MODULES | sed 's/json//g'); fi && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates wget curl cron tzdata procps && \
    if [ $(uname -m) = "aarch64" ]; then \
        apt-get install -y libatomic1; \
    fi && \
    mkdir -p /tmp/openlitespeed-release && \
    wget -qO- https://github.com/litespeedtech/openlitespeed/releases/download/v${OPENLITESPEED_VERSION}/openlitespeed-${OPENLITESPEED_VERSION}-$(uname -m)-linux.tgz | tar xvz -C /tmp/openlitespeed-release --strip-components=1 && \
    if [[ $PHP_VERSION != 7* ]]; then sed -i "s/^USE_LSPHP7=.*/USE_LSPHP7=no/" /tmp/openlitespeed-release/ols.conf; fi && \
    sed -i "s/^LSPHPVER=.*/LSPHPVER=${PHP_VERSION//./}/" /tmp/openlitespeed-release/_in.sh && \
    cd /tmp/openlitespeed-release && \
    ./install.sh && \
    rm -rf /tmp/openlitespeed-release && \
    echo 'cloud-docker' > /usr/local/lsws/PLAT && \
    wget -O /etc/apt/trusted.gpg.d/lst_debian_repo.gpg http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg; \
    wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg; \
    if [ -e /etc/apt/sources.list.d/lst_debian_repo.list ]; then \
        rm /etc/apt/sources.list.d/lst_debian_repo.list; \
    fi && \
    echo "deb http://rpms.litespeedtech.com/debian/ bullseye main" > /etc/apt/sources.list.d/lst_debian_repo.list && \
    echo "#deb http://rpms.litespeedtech.com/edge/debian/ bullseye main" >> /etc/apt/sources.list.d/lst_debian_repo.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends default-mysql-client lsphp${PHP_VERSION//./} lsphp${PHP_VERSION//./}-common $(for module in $PHP_MODULES; do echo -n "lsphp${PHP_VERSION//./}-$module "; done) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    wget -O /usr/local/lsws/admin/misc/lsup.sh https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
    chmod +x /usr/local/lsws/admin/misc/lsup.sh && \
    rm -rf /usr/local/lsws/conf/templates/*

# Add configuration files
ADD openlitespeed/admin/conf/htpasswd /usr/local/lsws/admin/conf/htpasswd
ADD openlitespeed/conf/httpd_config.conf /usr/local/lsws/conf/httpd_config.conf
ADD openlitespeed/conf/templates/docker.conf /usr/local/lsws/conf/templates/docker.conf

##
# Set Up Openlitespeed
# - set permissions on conf files
# - create default vhost docroot
# - set permissions on docroot
# - remove example site files
# - remove default listener
# - symlink lsphp to lsphp${PHP_VERSION//./}
# - symlink newly created lsphp${PHP_VERSION//./} to lsphp in fcgi-bin
# - symlink php binary to /usr/bin/php
##
RUN chown 999:999 /usr/local/lsws/conf -R && \
    mkdir -p /var/www/vhosts/_default/public && \
    chown 1000:1000 /var/www/vhosts/_default/ -R && \
    rm -rf /usr/local/lsws/Example && \
    sed -i -e '/virtualHost Example{/,/}/d' -e '/listener Default{/,/}/d' /usr/local/lsws/conf/httpd_config.conf && \
    cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/ && \
    cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/ && \
    ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp${PHP_VERSION//./} && \
    ln -sf /usr/local/lsws/fcgi-bin/lsphp${PHP_VERSION//./} /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/php /usr/bin/php && \
    touch /usr/local/lsws/conf/vhosts.env

# Set Up Container
EXPOSE 7080 80
ENV PATH="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /var/www/vhosts/
