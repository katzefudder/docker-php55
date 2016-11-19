#!/usr/bin/env bash
/etc/init.d/ssh start

apachectl -d /etc/apache2 -f /etc/apache2/apache2.conf -e info -DFOREGROUND