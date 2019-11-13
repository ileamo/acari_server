#!/bin/bash
set -e
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
chown app /var/log
setcap cap_net_admin=ep /opt/app/erts-10.5.2/bin/beam.smp cap_net_admin=ep /sbin/ip
exec su-exec app /opt/app/bin/bogatka_docker $@
