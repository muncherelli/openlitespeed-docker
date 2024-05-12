ARG BASE_IMAGE=phusion/baseimage:jammy-1.0.4
FROM ${BASE_IMAGE}
ARG OPENLITESPEED_VERSION=1.8.1

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget zip unzip

COPY . /build-openlitespeed-docker-${OPENLITESPEED_VERSION}

RUN /build-openlitespeed-docker-${OPENLITESPEED_VERSION}/install_openlitespeed.sh
RUN /build-openlitespeed-docker-${OPENLITESPEED_VERSION}/install_lsphp.sh

RUN rm -rf /build-openlitespeed-docker-${OPENLITESPEED_VERSION}

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



RUN mkdir /etc/service/openlitespeed
COPY run_openlitespeed.sh /etc/service/openlitespeed/run
RUN chmod +x /etc/service/openlitespeed/run

COPY boot_openlitespeed.sh /etc/my_init.d/openlitespeed.sh
RUN chmod +x /etc/my_init.d/openlitespeed.sh
