#!/bin/bash
. .env.versions

if [[ -z "$MDCX_IMAGE_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(MDCX_IMAGE_VERSION)！"
  exit
fi

docker push stainless403/mdcx:latest
docker push stainless403/mdcx:$MDCX_IMAGE_VERSION