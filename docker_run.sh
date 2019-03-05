#!/bin/sh

# Network
docker network create acari-network

# PostgreSQL
docker run --rm -it \
--name acari-server-db \
--network acari-network \
-e POSTGRES_PASSWORD=postgres \
-e POSTGRES_DB=acari_server_prod \
-e PGDATA=/var/lib/postgresql-a/data/pgdata \
-d ileamo/acari-server-db:init-25

# Server
docker run --rm -it \
--name acari-server \
--network acari-network \
-e DB_HOST=acari-server-db \
-p 50019:50019 \
-p 50020:50020 \
-p 50051:50051 \
--cap-add=NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
-d acari-server foreground

# Client
docker run --rm -it \
--name acari-client \
--network acari-network \
--cap-add=NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
-d acari-client

#docker exec -it \
#--user root \
#acari-client /usr/sbin/sshd

# Подключение сервера к внешней сети
# docker network create -d macvlan --subnet=10.0.0.0/8 --gateway=10.2.10.1 -o parent=eth0 acari-network-mac
#docker network connect acari-network-mac acari-server --ip 10.2.10.10
