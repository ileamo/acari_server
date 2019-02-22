#!/bin/sh

#postgres
docker run --rm -it \
--name acari-server-db \
--network acari-server-network \
-e POSTGRES_PASSWORD=postgres \
-e POSTGRES_DB=acari_server_prod \
-d postgres:alpine

#seed
docker run --rm -it \
--network acari-server-network \
acari-server seed

#server
docker run --rm -it \
--name acari-server \
--network acari-server-network \
-p 50020:50020 \
--cap-add=NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
acari-server console

#client
docker run --rm -it \
--name acari-client \
--network acari-server-network \
--cap-add=NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
acari-client
