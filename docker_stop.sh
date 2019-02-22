#!/bin/sh
docker stop acari-client acari-server acari-server-db
docker network rm acari-network
