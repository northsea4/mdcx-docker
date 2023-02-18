#!/bin/sh

export LC_ALL=zh_CN.UTF-8

if command -v take-ownership > /dev/null 2>&1; then
  echo "😁 take-ownership /app and /mdcx-config"
  take-ownership /app
  take-ownership /mdcx-config
fi

cd /app

echo "⏳ 启动MDCx..."

exec /app/MDCx