#!/bin/sh

export LC_ALL=zh_CN.UTF-8

if command -v some_command > /dev/null 2>&1; then
  echo "😁 take-ownership /app and /mdcx_config"
  take-ownership /app
  take-ownership /mdcx_config
fi

cd /app

echo "⏳ 启动MDCx..."

exec /app/MDCx