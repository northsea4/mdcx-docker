#!/bin/sh

export QT_SCALE_FACTOR=1.5
export QT_AUTO_SCREEN_SCALE_FACTOR=1

cd /app

SCRIPT_PATH="/app-assets/cert-patch/ensure-cacert.sh"

if [ -f "$SCRIPT_PATH" ]; then
  echo "🔘 执行cacert.pem缺失问题的临时修复脚本"
  nohup "$SCRIPT_PATH" &
fi

echo "⏳ 启动MDCx..."

exec /app/MDCx