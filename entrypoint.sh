#!/bin/bash

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
    VHOSTS=$(cat /usr/local/lsws/conf/vhosts.env)
    
    # Check if VHOSTS is empty, if so, skip the following steps
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
