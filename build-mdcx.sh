#!/bin/bash
. .env.versions

if [[ -z "$MD_MDCX_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(MD_MDCX_VERSION)！"
  exit
fi

docker build . \
  --build-arg APP_VERSION=$MD_MDCX_VERSION \
  -f Dockerfile.mdcx \
  -t stainless403/mdcx:dev \
  -t stainless403/mdcx:latest

docker tag stainless403/mdcx:latest stainless403/mdcx:$MD_MDCX_VERSION