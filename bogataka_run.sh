  docker run -it --rm\
    --name ubootovo \
    --hostname ubootovo \
    -e DB_HOST=bogatka-db \
    -e DB_HOSTS_RW="bogatka-db:" \
    -e DB_HOSTS_RO="bogatka-db" \
    -p 443:50443 \
    -p 50019:50019 \
    -v /etc/ssl/bogatka:/etc/ssl/bogatka:ro \
    -v /var/log/bogatka_ubootovo:/var/log \
    -v /etc/localtime:/etc/localtime:ro \
    --link bogatka-db \
    --cap-add=NET_ADMIN \
    --device /dev/net/tun:/dev/net/tun \
    bogatka
