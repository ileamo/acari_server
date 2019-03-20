#!/bin/sh

# Network
docker network create acari-network

# ***** ZABBIX ******
# Zabbix DB
docker run -t \
  --name zabbix-postgres-server \
  --network acari-network \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix" \
  -e POSTGRES_DB="zabbix_pwd" \
  -v /var/lib/postgresql/docker/zabbix/data:/var/lib/postgresql/data \
  -v /etc/localtime:/etc/localtime:ro \
  -d postgres:latest

# Zabbix server
docker run -t \
  --name zabbix-server-pgsql \
  --network acari-network \
  -e DB_SERVER_HOST="zabbix-postgres-server" \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix" \
  -e POSTGRES_DB="zabbix_pwd" \
  --link zabbix-postgres-server:postgres \
  -p 10051:10051 \
  -v /etc/localtime:/etc/localtime:ro \
  -d zabbix/zabbix-server-pgsql:latest

# Zabbix WEB
docker run -t \
  --name zabbix-web-nginx-pgsql \
  --network acari-network \
  -e DB_SERVER_HOST="zabbix-postgres-server" \
  -e POSTGRES_USER="zabbix" \
  -e POSTGRES_PASSWORD="zabbix" \
  -e POSTGRES_DB="zabbix_pwd" \
  -e ZBX_SERVER_NAME="Zabbix NSG" \
  --link zabbix-postgres-server:postgres \
  --link zabbix-server-pgsql:zabbix-server \
  -p 80:80 \
  -v /etc/ssl/nginx:/etc/ssl/nginx:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -d zabbix/zabbix-web-nginx-pgsql:latest


# ***** ACARI *****

# PostgreSQL
docker run --rm -it \
  --name acari-server-db \
  --network acari-network \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=acari_server_prod \
  -e PGDATA=/var/lib/postgresql-a/data/pgdata \
  -v /etc/localtime:/etc/localtime:ro \
  -d ileamo/acari-server-db:init-25

# Server
docker run --rm -it \
  --name acari-server \
  --network acari-network \
  -e DB_HOST=acari-server-db \
  -p 50019:50019 \
  -p 50020:50020 \
  -v /var/log/acari_server:/tmp/app/log \
  -v /etc/localtime:/etc/localtime:ro \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -d acari-server foreground

# Client
docker run --rm -it \
  --name acari-client \
  --network acari-network \
  -v /var/log/acari_client:/tmp/app/log \
  -v /etc/localtime:/etc/localtime:ro \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  -d acari-client

#docker exec -it \
#--user root \
#acari-client /usr/sbin/sshd

# Подключение сервера к внешней сети
# docker network create -d macvlan --subnet=10.0.0.0/8 --gateway=10.2.10.1 -o parent=eth0 acari-network-mac
#docker network connect acari-network-mac acari-server --ip 10.2.10.10
