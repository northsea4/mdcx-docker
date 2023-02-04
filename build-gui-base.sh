#!/bin/bash
. .env.versions

if [[ -z "$GUI_BASE_VERSION" ]]; then
  echo "请在 .env.versions 中指定版本号(GUI_BASE_VERSION)！示例：0.2.5"
  exit
fi

docker build . \
  --build-arg APP_VERSION=$GUI_BASE_VERSION \
  -f Dockerfile.gui-base \
  -t stainless403/gui-base:dev \
  -t stainless403/gui-base:latest

docker tag stainless403/gui-base:latest stainless403/gui-base:$GUI_BASE_VERSION