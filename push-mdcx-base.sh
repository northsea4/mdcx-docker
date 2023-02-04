#!/bin/bash
. .env.versions

if [[ -z "$MDCX_BASE_IMAGE_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(MDCX_BASE_IMAGE_VERSION)！"
  exit
fi

docker push stainless403/mdcx-base:latest
docker push stainless403/mdcx-base:$MDCX_BASE_IMAGE_VERSION