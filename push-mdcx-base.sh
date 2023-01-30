#!/bin/bash
. .env.versions

if [[ -z "$MD_MDCX_BASE_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(MD_MDCX_BASE_VERSION)！"
  exit
fi

docker push stainless403/mdcx-base:latest
docker push stainless403/mdcx-base:$MD_MDCX_BASE_VERSION