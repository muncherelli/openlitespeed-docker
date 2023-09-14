#!/bin/bash

PHP_INI="/usr/local/lsws/lsphp${PHP_VERSION//./}/etc/php/${PHP_VERSION}/litespeed/php.ini"

if [ -f $PHP_INI ]; then
    # Substitute memory_limit value in php.ini with ENV variable
    sed -i "s/^memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/" $PHP_INI
    # Substitute post_max_size value in php.ini with ENV variable
    sed -i "s/^post_max_size = .*/post_max_size = ${PHP_POST_MAX_SIZE}/" $PHP_INI
    # Substitute upload_max_filesize value in php.ini with ENV variable
    sed -i "s/^upload_max_filesize = .*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" $PHP_INI
    # Substitute max_input_time value in php.ini with ENV variable
    sed -i "s/^max_input_time = .*/max_input_time = ${PHP_MAX_INPUT_TIME}/" $PHP_INI
    # Substitute max_execution_time value in php.ini with ENV variable
    sed -i "s/^max_execution_time = .*/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/" $PHP_INI
    # Substitute max_input_vars value in php.ini with ENV variable
    if grep -q '^max_input_vars =' $PHP_INI; then
        sed -i "s/^max_input_vars = .*/max_input_vars = ${PHP_MAX_INPUT_VARS}/" $PHP_INI
    else
        echo "max_input_vars = ${PHP_MAX_INPUT_VARS}" >> $PHP_INI
    fi
fi

if [ -z "$(ls -A -- "/usr/local/lsws/conf/")" ]; then
    cp -R /usr/local/lsws/.conf/* /usr/local/lsws/conf/
fi
if [ -z "$(ls -A -- "/usr/local/lsws/admin/conf/")" ]; then
    cp -R /usr/local/lsws/admin/.conf/* /usr/local/lsws/admin/conf/
fi
chown 999:999 /usr/local/lsws/conf -R
chown 999:1000 /usr/local/lsws/admin/conf -R

# New function to check server and restart
function check_server_and_restart {
    while true; do
        if /usr/local/lsws/bin/lswsctrl status | /bin/grep 'litespeed is running with PID *' > /dev/null; then
            /usr/local/lsws/bin/lswsctrl restart
            break
        fi
        sleep 1
    done
}

# Function to process vhosts
function process_vhosts {
    if [ -z "$VHOSTS" ]; then
        return
    fi
    
    # Delete the default member block
    sed -i '/member .* {/,/}/d' /usr/local/lsws/conf/httpd_config.conf

    # Delete any existing vhosts
    sed -i '/member .*/d' /usr/local/lsws/conf/httpd_config.conf

    # Add each vhost
    IFS=',' read -ra ADDR <<< "$VHOSTS"
    for i in "${ADDR[@]}"; do
        sed -i "/note                    docker/a\  member $i" /usr/local/lsws/conf/httpd_config.conf
    done

    # Call function to check server status and restart
    check_server_and_restart
}


# Monitor for changes in VHOSTS
OPENLITESPEED_VHOSTS_ENV_LAST_HASH=""
while true; do
    OPENLITESPEED_VHOSTS_ENV_CURRENT_HASH=$(cat /usr/local/lsws/conf/vhosts.env | md5sum | cut -d " " -f1)
    if [ "$OPENLITESPEED_VHOSTS_ENV_CURRENT_HASH" != "$OPENLITESPEED_VHOSTS_ENV_LAST_HASH" ]; then
        process_vhosts
        OPENLITESPEED_VHOSTS_ENV_LAST_HASH=$OPENLITESPEED_VHOSTS_ENV_CURRENT_HASH
    fi
    sleep 5
done &

/usr/local/lsws/bin/lswsctrl start
$@
while true; do
    if ! /usr/local/lsws/bin/lswsctrl status | /bin/grep 'litespeed is running with PID *' > /dev/null; then
        break
    fi
    sleep 60
done
