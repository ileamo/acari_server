#!/bin/bash
set -e
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
chown app /var/log
exec su-exec app /opt/app/bin/bogatka_docker $@
