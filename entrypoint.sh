#!/bin/bash

if [ -z "$(ls -A -- "/usr/local/lsws/conf/")" ]; then
    cp -R /usr/local/lsws/.conf/* /usr/local/lsws/conf/
fi
if [ -z "$(ls -A -- "/usr/local/lsws/admin/conf/")" ]; then
    cp -R /usr/local/lsws/admin/.conf/* /usr/local/lsws/admin/conf/
fi
chown 999:999 /usr/local/lsws/conf -R
chown 999:1000 /usr/local/lsws/admin/conf -R

# Function to process vhosts
function process_vhosts {
    VHOSTS=$(cat /usr/local/lsws/conf/vhosts.env)
    # Delete existing members
    sed -i '/  member /d' /usr/local/lsws/conf/httpd.conf

    # Add each vhost
    IFS=',' read -ra ADDR <<< "$VHOSTS"
    for i in "${ADDR[@]}"; do
        sed -i "/vhTemplate docker {/a\  member $i" /usr/local/lsws/conf/httpd.conf
    done

    # Restart server
    /usr/local/lsws/bin/lswsctrl restart
}

# Monitor for changes in VHOSTS
OPENLITESPEED_VHOSTS_ENV_LAST_HASH=""
while true; do
    if [ -s "/usr/local/lsws/conf/vhosts.env" ]; then
        OPENLITESPEED_VHOSTS_ENV_CURRENT_HASH=$(md5sum /usr/local/lsws/conf/vhosts.env | cut -d " " -f1)
        if [ "$OPENLITESPEED_VHOSTS_ENV_CURRENT_HASH" != "$OPENLITESPEED_VHOSTS_ENV_LAST_HASH" ]; then
            process_vhosts
            OPENLITESPEED_VHOSTS_ENV_LAST_HASH=$OPENLITESPEED_VHOSTS_ENV_CURRENT_HASH
        fi
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
