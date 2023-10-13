#!/bin/sh

if [ -n "$DEBUG_CONTAINER" ]; then
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


if [ -f "/cert-patch/ensure-cacert.sh" ]; then
  echo "🔘 执行cacert.pem缺失问题的临时修复脚本"
  nohup /cert-patch/ensure-cacert.sh &
fi

echo "⏳ 启动MDCx..."

exec /app/MDCx