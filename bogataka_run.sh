  docker run -it --rm\
    --name ubootovo \
    --hostname ubootovo \
    -e DB_HOST=acari-server-db \
    -e DB_HOSTS_RW="acari-server-db" \
    -e DB_HOSTS_RO="acari-server-db" \
    -p 443:50443 \
    -p 50019:50019 \
    -v /etc/ssl/acari:/etc/ssl/acari:ro \
    -v /var/log/acari_ubootovo:/var/log \
    -v /etc/localtime:/etc/localtime:ro \
    --link acari-server-db \
    --cap-add=NET_ADMIN \
    --device /dev/net/tun:/dev/net/tun \
    bogatka
