FROM docker.io/debian:bullseye-slim
ARG OPENLITESPEED_VERSION=1.7.17
ARG PHP_VERSION=8.2

# Use bash shell
SHELL ["/bin/bash", "-c"]

# Update system packages and install necessary dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates wget curl cron tzdata procps && \
    if [ $(uname -m) = "aarch64" ]; then \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y libatomic1; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Install Openlitespeed and nullify php package install function from install.sh since we will likely install PHP separately
RUN mkdir -p /tmp/openlitespeed-release && \
    wget -qO- https://github.com/litespeedtech/openlitespeed/releases/download/v${OPENLITESPEED_VERSION}/openlitespeed-${OPENLITESPEED_VERSION}-$(uname -m)-linux.tgz | tar xvz -C /tmp/openlitespeed-release --strip-components=1 && \
    if [[ $PHP_VERSION != 7* ]]; then sed -i "s/^USE_LSPHP7=.*/USE_LSPHP7=no/" /tmp/openlitespeed-release/ols.conf; fi && \
    sed -i "s/^LSPHPVER=.*/LSPHPVER=${PHP_VERSION//./}/" /tmp/openlitespeed-release/_in.sh && \
    cd /tmp/openlitespeed-release && \
    ./install.sh && \
    rm -rf /tmp/openlitespeed-release && \
    echo 'cloud-docker' > /usr/local/lsws/PLAT

# Ensure lsphp${PHP_VERSION//./} is installed and necessary PHP modules
RUN if [ ! -e /etc/apt/trusted.gpg.d/lst_debian_repo.gpg ]; then \
        wget -O /etc/apt/trusted.gpg.d/lst_debian_repo.gpg http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg; \
    fi && \
    if [ ! -e /etc/apt/trusted.gpg.d/lst_repo.gpg ]; then \
        wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg; \
    fi && \
    if [ -e /etc/apt/sources.list.d/lst_debian_repo.list ]; then \
        rm /etc/apt/sources.list.d/lst_debian_repo.list; \
    fi && \
    echo "deb http://rpms.litespeedtech.com/debian/ bullseye main" > /etc/apt/sources.list.d/lst_debian_repo.list && \
    echo "#deb http://rpms.litespeedtech.com/edge/debian/ bullseye main" >> /etc/apt/sources.list.d/lst_debian_repo.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    default-mysql-client lsphp${PHP_VERSION//./} lsphp${PHP_VERSION//./}-common lsphp${PHP_VERSION//./}-mysql lsphp${PHP_VERSION//./}-opcache \
    lsphp${PHP_VERSION//./}-curl lsphp${PHP_VERSION//./}-imap lsphp${PHP_VERSION//./}-sqlite3 lsphp${PHP_VERSION//./}-redis lsphp${PHP_VERSION//./}-intl

# Install PHP modules for PHP 7
RUN if [[ $PHP_VERSION == 7* ]]; then apt-get install lsphp${PHP_VERSION//./}-json -y; fi && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O /usr/local/lsws/admin/misc/lsup.sh \
    https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
    chmod +x /usr/local/lsws/admin/misc/lsup.sh

EXPOSE 7080 8000
ENV PATH="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

ADD openlitespeed/conf/templates/docker.conf /usr/local/lsws/conf/templates/docker.conf
ADD openlitespeed/bin/setup_docker.sh /usr/local/lsws/bin/setup_docker.sh
ADD openlitespeed/conf/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
ADD openlitespeed/admin/conf/htpasswd /usr/local/lsws/admin/conf/htpasswd

# Setup docker and cleanup
RUN /usr/local/lsws/bin/setup_docker.sh && rm /usr/local/lsws/bin/setup_docker.sh && \
    chown 999:999 /usr/local/lsws/conf -R  && \
    cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/ && \
    cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/

RUN if [[ $PHP_VERSION == 8* ]]; then ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8; fi && \
    if [[ $PHP_VERSION == 8* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp; fi && \
    if [[ $PHP_VERSION == 7* ]]; then ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7; fi && \
    if [[ $PHP_VERSION == 7* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp7 /usr/local/lsws/fcgi-bin/lsphp; fi && \
    ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/php /usr/bin/php

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /var/www/vhosts/
