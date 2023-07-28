#!/usr/bin/env bash
echo "listener HTTP {
  address                 *:80
  secure                  0
}

vhTemplate docker {
  templateFile            conf/templates/docker.conf
  listeners               HTTP
  note                    docker

  member localhost {
    vhDomain              localhost, *
  }
}

" >> /usr/local/lsws/conf/httpd_config.conf

mkdir -p /var/www/vhosts/localhost/{html,logs,certs}
chown 1000:1000 /var/www/vhosts/localhost/ -R