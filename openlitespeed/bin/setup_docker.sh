#!/usr/bin/env bash
echo "listener HTTP {
  address                 *:80
  secure                  0
}

vhTemplate docker {
  templateFile            conf/templates/docker.conf
  listeners               HTTP
  note                    docker

  member _default {
    vhDomain              *
  }
}

" >> /usr/local/lsws/conf/httpd_config.conf