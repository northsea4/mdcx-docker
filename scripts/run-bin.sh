#!/bin/sh

if [ -n "$DEBUG" ]; then
  echo "=========================!!!!!!!!=============================="
  echo "            I'm sleeping. Make yourself at home!"
  echo "=========================!!!!!!!!=============================="

  while :
  do
    sleep 10
  done
fi

export LC_ALL=zh_CN.UTF-8

cd /app

echo "⏳ 启动MDCx..."

exec /app/MDCx