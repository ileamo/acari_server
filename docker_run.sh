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
-p 50020:50020 \
--cap-add=NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
-d acari-server console

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
