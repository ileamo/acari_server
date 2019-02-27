#!/bin/sh

#docker commit acari-server-db ileamo/acari-server-db:init-25
docker stop acari-client acari-server acari-server-db
docker network rm acari-network
