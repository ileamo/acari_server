#!/bin/sh

if [ "$#" = "0" ]
then
  echo "No servers defined"
  exit 1
fi

if ! [ -x "$(command -v curl)" ]
then
  echo "curl not found"
  exit 1
fi


WORK_DIR=/tmp/acari
mkdir -p $WORK_DIR
cd $WORK_DIR
rm -rf *

cp /proc/nsg/env env
. ./env
ID="$nsg_device"_"$serial_num"
echo "ID=${ID}"

for host in $@
do
  curl -H "Content-Type: application/json" \
    --silent --show-error --insecure \
    -X POST \
    -d  "{\"method\":\"get.conf\",\"params\":{\"id\":\"${ID}\"}}" \
    --output setup.sh \
    ${host}/api

  curl_exit_code=$?
  if [ "$curl_exit_code" = "0" ]; then break; fi
done

if [ "$curl_exit_code" != "0" ]
then
  echo "Can't connect to any server"
  exit  $curl_exit_code
fi

sh ./setup.sh --nox11 --keep --noprogress
