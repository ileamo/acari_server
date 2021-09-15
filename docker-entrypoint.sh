#!/bin/bash
set -e
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
if [[ ! -z "$ETH0_STATIC_IP" ]]; then
  ip address add dev eth0 $ETH0_STATIC_IP
fi
chown docker /var/log
setcap cap_net_admin=ep /opt/app/erts-11.2/bin/beam.smp \
  cap_net_admin=ep /sbin/ip
#su - docker -c "screen -d -m -h 4096 /bin/bash"
exec su-exec docker /opt/app/bin/bogatka_docker $@


