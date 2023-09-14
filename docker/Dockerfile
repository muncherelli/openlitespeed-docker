FROM docker.io/debian:bullseye-slim
ARG OPENLITESPEED_VERSION=1.7.17
ARG PHP_VERSION=8.2
ARG PHP_EXTENSIONS="curl,intl,imagick,imap,mysql,opcache,pgsql,sqlite3,redis"

# Set Up PHP configuration variables
ENV PHP_MEMORY_LIMIT=512M
ENV PHP_POST_MAX_SIZE=128M
ENV PHP_UPLOAD_MAX_FILESIZE=128M
ENV PHP_MAX_INPUT_TIME=300
ENV PHP_MAX_EXECUTION_TIME=300
ENV PHP_MAX_INPUT_VARS=2500
ENV VHOSTS=

# Use bash shell
SHELL ["/bin/bash", "-c"]

##
# Install Openlitespeed:
# - Update the list of available packages and dependencies using 'apt-get update'
# - Install required dependencies using 'apt-get install'. These dependencies include ca-certificates, wget, curl, cron, tzdata, and procps. 
# - Check for the system's architecture. If it is "aarch64", then it installs the 'libatomic1' package.
# - Create a directory '/tmp/openlitespeed-release' for storing OpenLiteSpeed release files
# - Download and extract OpenLiteSpeed release file from the URL and extract it into '/tmp/openlitespeed-release' directory
# - If PHP version isn't 7.x, it adjusts the openlitespeed installer configuration to not use 'lsphp7'
# - Sets the PHP version in the OpenLiteSpeed installation script
# - Navigates to the '/tmp/openlitespeed-release' directory and runs the install script to install OpenLiteSpeed
# - Removes the '/tmp/openlitespeed-release' directory after installation is completed
# - Downloads GPG keys for the LiteSpeed repositories and adds them to trusted sources
# - Removes existing LiteSpeed repository from the sources list if exists, then adds new LiteSpeed repositories to the sources list
# - If 'PHP_EXTENSIONS' variable doesn't end with a comma, appends a comma at the end
# - Adjusts the 'PHP_EXTENSIONS' variable based on the PHP version and system architecture
# - Updates the list of available packages and dependencies again
# - Installs the specified version of PHP, its common modules, and additional PHP modules specified in '$PHP_EXTENSIONS' 
# - If PHP version is 7.x, it also installs 'lsphpXX-json'
# - Cleans the apt cache and removes temporary files
# - Downloads 'lsup.sh' script from GitHub and saves it to '/usr/local/lsws/admin/misc'. It then makes this script executable
# - Removes all existing templates in '/usr/local/lsws/conf/templates' directory
##
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates wget curl cron tzdata procps zip unzip && \
    if [ $(uname -m) = "aarch64" ]; then \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libatomic1; \
    fi && \
    mkdir -p /tmp/openlitespeed-release && \
    wget -qO- https://github.com/litespeedtech/openlitespeed/releases/download/v${OPENLITESPEED_VERSION}/openlitespeed-${OPENLITESPEED_VERSION}-$(uname -m)-linux.tgz | tar xvz -C /tmp/openlitespeed-release --strip-components=1 && \
    if [[ $PHP_VERSION != 7* ]]; then sed -i "s/^USE_LSPHP7=.*/USE_LSPHP7=no/" /tmp/openlitespeed-release/ols.conf; fi && \
    sed -i "s/^LSPHPVER=.*/LSPHPVER=${PHP_VERSION//./}/" /tmp/openlitespeed-release/_in.sh && \
    cd /tmp/openlitespeed-release && \
    ./install.sh && \
    rm -rf /tmp/openlitespeed-release && \
    wget -O /etc/apt/trusted.gpg.d/lst_debian_repo.gpg http://rpms.litespeedtech.com/debian/lst_debian_repo.gpg; \
    wget -O /etc/apt/trusted.gpg.d/lst_repo.gpg http://rpms.litespeedtech.com/debian/lst_repo.gpg; \
    if [ -e /etc/apt/sources.list.d/lst_debian_repo.list ]; then \
        rm /etc/apt/sources.list.d/lst_debian_repo.list; \
    fi && \
    echo "deb http://rpms.litespeedtech.com/debian/ bullseye main" > /etc/apt/sources.list.d/lst_debian_repo.list && \
    echo "#deb http://rpms.litespeedtech.com/edge/debian/ bullseye main" >> /etc/apt/sources.list.d/lst_debian_repo.list && \
    if [ "${PHP_EXTENSIONS: -1}" != "," ]; then \
        PHP_EXTENSIONS="${PHP_EXTENSIONS},"; \
    fi && \
    if [ "$PHP_VERSION" = "7.4" ] && [ "$(uname -m)" = "x86_64" ]; then \
        PHP_EXTENSIONS=$(echo $PHP_EXTENSIONS | sed 's/redis,//g'); \
    fi && \
    if [ "$PHP_VERSION" = "8.0" ]; then \
        PHP_EXTENSIONS=$(echo $PHP_EXTENSIONS | sed 's/redis,//g'); \
    fi && \
    if [ "$PHP_VERSION" = "8.0" ] && [ "$(uname -m)" = "aarch64" ]; then \
        PHP_EXTENSIONS=$(echo $PHP_EXTENSIONS | sed 's/imagick,//g'); \
    fi && \
    PHP_EXTENSIONS=$(echo $PHP_EXTENSIONS | sed 's/,$//') && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends default-mysql-client lsphp${PHP_VERSION//./} lsphp${PHP_VERSION//./}-common $(echo $PHP_EXTENSIONS | tr ',' '\n' | while read ext; do echo -n "lsphp${PHP_VERSION//./}-$ext "; done) && \
    if [[ $PHP_VERSION == 7* ]]; then DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends lsphp${PHP_VERSION//./}-json; fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    wget -O /usr/local/lsws/admin/misc/lsup.sh https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && chmod +x /usr/local/lsws/admin/misc/lsup.sh && \
    rm -rf /usr/local/lsws/conf/templates/*

# Add configuration files
ADD lsws/PLAT /usr/local/lsws/PLAT
ADD lsws/admin/conf/htpasswd /usr/local/lsws/admin/conf/htpasswd
ADD lsws/conf/httpd_config.conf /usr/local/lsws/conf/httpd_config.conf
ADD lsws/conf/templates/docker.conf /usr/local/lsws/conf/templates/docker.conf

##
# Set Up Openlitespeed
# - Sets permissions on the OpenLiteSpeed configuration directory '/usr/local/lsws/conf' and all its content to user with user ID 999 and group ID 999
# - Creates a default vhost document root directory '/var/www/vhosts/_default/public'
# - Sets permissions on the '/var/www/vhosts/_default/' directory and all its content to user with user ID 1000 and group ID 1000
# - Removes the OpenLiteSpeed example site files located in '/usr/local/lsws/Example'
# - Removes the 'virtualHost Example' and 'listener Default' blocks from the OpenLiteSpeed HTTPD configuration file '/usr/local/lsws/conf/httpd_config.conf'
# - Copies the '/usr/local/lsws/conf/' directory and all its contents to '/usr/local/lsws/.conf/'
# - Copies the '/usr/local/lsws/admin/conf' directory and all its contents to '/usr/local/lsws/admin/.conf/'
# - Creates a symbolic link between the 'lsphp' binary in the PHP version specific directory and a new 'lsphp' binary in the 'fcgi-bin' directory
# - Creates a symbolic link between the newly created 'lsphp' binary in 'fcgi-bin' directory and the 'lsphp' binary in the same directory
# - Creates a symbolic link between the 'php' binary in the PHP version specific directory and the 'php' binary in '/usr/bin' directory
# - Creates an empty 'vhosts.env' file in the '/usr/local/lsws/conf' directory
##
RUN chown 999:999 /usr/local/lsws/conf -R && \
    mkdir -p /var/www/vhosts/localhost/public && \
    chown 1000:1000 /var/www/vhosts/localhost/ -R && \
    rm -rf /usr/local/lsws/Example && \
    cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/ && \
    cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/ && \
    ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp${PHP_VERSION//./} && \
    ln -sf /usr/local/lsws/fcgi-bin/lsphp${PHP_VERSION//./} /usr/local/lsws/fcgi-bin/lsphp && \
    ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/php /usr/bin/php && \
    ln -sf /usr/local/lsws/lsphp${PHP_VERSION//./}/bin/phpize /usr/bin/phpize

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set Up Container
EXPOSE 7080 80
ENV PATH="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

# This is not to override the PHP version. Simply passes the ARG value over to entrypoint.sh
ENV PHP_VERSION=${PHP_VERSION}
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /var/www/vhosts/
