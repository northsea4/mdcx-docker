#!/bin/bash
. .env.versions

if [[ -z "$GUI_BASE_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(GUI_BASE_VERSION)！"
  exit
fi

docker push stainless403/gui-base:latest
docker push stainless403/gui-base:$GUI_BASE_VERSION