FROM docker.io/debian:bullseye-slim
ARG OPENLITESPEED_VERSION=1.7.17
ARG PHP_VERSION=lsphp82

# Update system packages and install necessary dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates wget curl cron tzdata procps && \
    if [ $(uname -m) = "aarch64" ]; then \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y libatomic1; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Install Openlitespeed and nullify php package install function from install.sh since we will install PHP separately
RUN mkdir -p /tmp/openlitespeed-release && \
    wget -qO- https://github.com/litespeedtech/openlitespeed/releases/download/v${OPENLITESPEED_VERSION}/openlitespeed-${OPENLITESPEED_VERSION}-$(uname -m)-linux.tgz | tar xvz -C /tmp/openlitespeed-release --strip-components=1 && \
    cd /tmp/openlitespeed-release && \
    sed -i '/install_lsphp7_debian()/{N;N;N;d}' ./_in.sh && \
    sed -i '/install_lsphp7_debian()/a \    :' ./_in.sh && \
    ./install.sh && \
    rm -rf /tmp/openlitespeed-release && \
    echo 'cloud-docker' > /usr/local/lsws/PLAT

# Install PHP_VERSION and necessary PHP modules
RUN wget -O /etc/apt/trusted.gpg.d/lst_debian_repo.gpg http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg && \
    wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg && \
    echo "deb http://rpms.litespeedtech.com/debian/ bullseye main" > /etc/apt/sources.list.d/lst_debian_repo.list && \
    echo "#deb http://rpms.litespeedtech.com/edge/debian/ bullseye main" >> /etc/apt/sources.list.d/lst_debian_repo.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    default-mysql-client $PHP_VERSION $PHP_VERSION-common $PHP_VERSION-mysql $PHP_VERSION-opcache \
    $PHP_VERSION-curl $PHP_VERSION-imagick $PHP_VERSION-redis $PHP_VERSION-intl

# Install PHP modules for PHP 7
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then apt-get install $PHP_VERSION-json -y; fi"] && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O /usr/local/lsws/admin/misc/lsup.sh \
    https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
    chmod +x /usr/local/lsws/admin/misc/lsup.sh

EXPOSE 7080 8000
ENV PATH="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

ADD lsws/conf/templates/docker.conf /usr/local/lsws/conf/templates/docker.conf
ADD lsws/bin/setup_docker.sh /usr/local/lsws/bin/setup_docker.sh
ADD lsws/conf/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
ADD lsws/admin/conf/htpasswd /usr/local/lsws/admin/conf/htpasswd

# Setup docker and cleanup
RUN /usr/local/lsws/bin/setup_docker.sh && rm /usr/local/lsws/bin/setup_docker.sh && \
    chown 999:999 /usr/local/lsws/conf -R  && \
    cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/ && \
    cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/

# Setup PHP
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8; fi"] && \
    ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp; fi"] && \
    ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7; fi"] && \
    ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp7 /usr/local/lsws/fcgi-bin/lsphp; fi"]

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /var/www/vhosts/
