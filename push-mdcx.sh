#!/bin/bash
. .env.versions

if [[ -z "$MD_MDCX_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(MD_MDCX_VERSION)！"
  exit
fi

docker push stainless403/mdcx:latest
docker push stainless403/mdcx:$MD_MDCX_VERSION