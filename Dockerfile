FROM docker.io/debian:bullseye-slim
ARG OPENLITESPEED_VERSION=1.7.17
ARG PHP_VERSION=lsphp82

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates wget curl cron tzdata procps && \
    if [ $(uname -m) = "aarch64" ]; then \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y libatomic1; \
    fi && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/ols
RUN wget -qO- https://github.com/litespeedtech/openlitespeed/releases/download/v${OPENLITESPEED_VERSION}/openlitespeed-${OPENLITESPEED_VERSION}-$(uname -m)-linux.tgz | tar xvz -C /tmp/ols --strip-components=1 && \
	cd /tmp/ols && ./install.sh && rm -rf /tmp/ols && echo 'cloud-docker' > /usr/local/lsws/PLAT

RUN wget -O /etc/apt/trusted.gpg.d/lst_debian_repo.gpg http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg
RUN wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg
RUN echo "deb http://rpms.litespeedtech.com/debian/ bullseye main" > /etc/apt/sources.list.d/lst_debian_repo.list
RUN echo "#deb http://rpms.litespeedtech.com/edge/debian/ bullseye main" >> /etc/apt/sources.list.d/lst_debian_repo.list

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    default-mysql-client $PHP_VERSION $PHP_VERSION-common $PHP_VERSION-mysql $PHP_VERSION-opcache \
    $PHP_VERSION-curl $PHP_VERSION-imagick $PHP_VERSION-redis $PHP_VERSION-intl && \
    rm -rf /var/lib/apt/lists/*

RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then apt-get install $PHP_VERSION-json -y; fi"]

RUN wget -O /usr/local/lsws/admin/misc/lsup.sh \
    https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
    chmod +x /usr/local/lsws/admin/misc/lsup.sh

EXPOSE 7080 8000
ENV PATH="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

ADD config/docker.conf /usr/local/lsws/conf/templates/docker.conf
ADD config/setup_docker.sh /usr/local/lsws/bin/setup_docker.sh
ADD config/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
ADD config/htpasswd /usr/local/lsws/admin/conf/htpasswd

RUN /usr/local/lsws/bin/setup_docker.sh && rm /usr/local/lsws/bin/setup_docker.sh
RUN chown 999:999 /usr/local/lsws/conf -R
RUN cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/
RUN cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/
#RUN sed -i "s|fcgi-bin/lsphp|/usr/local/lsws/$PHP_VERSION/bin/lsphp|g" /usr/local/lsws/conf/httpd_config.conf
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp7 /usr/local/lsws/fcgi-bin/lsphp; fi"]
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /var/www/vhosts/
