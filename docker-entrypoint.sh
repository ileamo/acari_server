#!/bin/bash
set -e
chown app /var/log
exec su-exec app /opt/app/bin/acari_server $1
