#!/bin/sh

# Network
docker network create acari-network

# ***** ZABBIX ******

# Zabbix DB
docker run -t \
  --name zabbix-postgres-server \
  --network acari-network \
  --restart unless-stopped \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix" \
  -e POSTGRES_DB="zabbix_pwd" \
  -v /var/lib/postgresql/docker/zabbix-acari-server/data:/var/lib/postgresql/data \
  -v /etc/localtime:/etc/localtime:ro \
  -d postgres:11.2-alpine

# Zabbix server
docker run -t \
  --name zabbix-server-pgsql \
  --network acari-network \
  --restart unless-stopped \
  -e DB_SERVER_HOST="zabbix-postgres-server" \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix" \
  -e POSTGRES_DB="zabbix_pwd" \
  --link zabbix-postgres-server:postgres \
  -v /etc/localtime:/etc/localtime:ro \
  -d zabbix/zabbix-server-pgsql:latest

# Zabbix WEB
docker run -t \
  --name zabbix-web-nginx-pgsql \
  --network acari-network \
  --restart unless-stopped \
  -e DB_SERVER_HOST="zabbix-postgres-server" \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix" \
  -e POSTGRES_DB="zabbix_pwd" \
  -e ZBX_SERVER_NAME="Zabbix NSG" \
  -e PHP_TZ="Europe/Moscow" \
  --link zabbix-postgres-server:postgres \
  --link zabbix-server-pgsql:zabbix-server \
  -p 10443:443 \
  -v /etc/ssl/acari:/etc/ssl/nginx:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -d zabbix/zabbix-web-nginx-pgsql:latest

docker run -t \
  --name acari-zabbix-agent \
  --network acari-network \
  --restart unless-stopped \
  -e ZBX_HOSTNAME="acari-server-1" \
  -e ZBX_SERVER_HOST="zabbix-server-pgsql" \
  --link zabbix-server-pgsql:zabbix-server \
  --privileged \
  -d zabbix/zabbix-agent:latest


# ***** ACARI *****

# PostgreSQL
docker run -t \
  --name acari-server-db \
  --network acari-network \
  --restart unless-stopped \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=acari_server_prod \
  -e PGDATA=/var/lib/postgresql-a/data/pgdata \
  -v /etc/localtime:/etc/localtime:ro \
  -d ileamo/acari-server-db:init-25

# Server
docker run -t \
  --name acari-server \
  --network acari-network \
  --restart unless-stopped \
  -e DB_HOST="acari-server-db" \
  -e ZBX_API_URL="http://zabbix-web-nginx-pgsql" \
  -e ZBX_WEB_PORT=10443 \
  -p 443:50020 \
  -v /etc/ssl/acari:/etc/ssl/acari:ro \
  -v /var/log/acari_server:/tmp/app/log \
  -v /etc/localtime:/etc/localtime:ro \
  --link acari-server-db \
  --link zabbix-web-nginx-pgsql \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -d ileamo/acari-server foreground

# Client
docker run -t \
  --name acari-client \
  --network acari-network \
  --restart unless-stopped \
  -v /var/log/acari_client:/tmp/app/log \
  -v /etc/localtime:/etc/localtime:ro \
  --link acari-server \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -d ileamo/acari-client



#docker exec -it \
#--user root \
#acari-client /usr/sbin/sshd

# Подключение сервера к внешней сети
# docker network create -d macvlan --subnet=10.0.0.0/8 --gateway=10.2.10.1 -o parent=eth0 acari-network-mac
#docker network connect acari-network-mac acari-server --ip 10.2.10.10
