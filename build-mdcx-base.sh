#!/bin/bash
. .env.versions

if [[ -z "$MDCX_BASE_IMAGE_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(MDCX_BASE_IMAGE_VERSION)！示例：0.2.5"
  exit
fi

docker build . \
  --build-arg APP_VERSION=$MDCX_BASE_IMAGE_VERSION \
  -f Dockerfile.mdcx-base \
  -t stainless403/mdcx-base:dev \
  -t stainless403/mdcx-base:latest

docker tag stainless403/mdcx-base:latest stainless403/mdcx-base:$MDCX_BASE_IMAGE_VERSION