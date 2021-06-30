docker run -t --rm \
  --init \
  --name bogatka \
  --hostname bogatka \
  --network bogatka \
  -e DB_HOSTS_RW="bogatka-db-master" \
  -e DB_HOSTS_RO="bogatka-db-master" \
  -p $HTTPS_PORT:50443 \
  -p $API_PORT:50444 \
  -p $ACARI_PORT:50019 \
  -p 80:50080 \
  -v /home/bogatka/opt/download:/opt/app/download \
  -v /etc/ssl/bogatka:/etc/ssl/bogatka:ro \
  -v /var/log/bogatka_local:/var/log \
  -v /etc/localtime:/etc/localtime:ro \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  bogatka:latest
