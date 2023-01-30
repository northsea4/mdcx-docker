#!/bin/bash
. .env.versions

if [[ -z "$MD_GUI_BASE_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(MD_GUI_BASE_VERSION)！"
  exit
fi

docker push stainless403/gui-base:latest
docker push stainless403/gui-base:$MD_GUI_BASE_VERSION