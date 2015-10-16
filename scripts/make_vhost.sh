#!/usr/bin/env bash
cat /tmp/vhost_template.txt | sed -e "s/###HOSTNAME###/$1/g" > $2