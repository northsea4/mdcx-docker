#!/bin/sh

if command -v take-ownership > /dev/null 2>&1; then
  echo "😁 take-ownership: /app and /mdcx-config"
  take-ownership /app
  take-ownership /mdcx-config
  
  if [ -d "/cert-patch" ]; then
    echo "😁 take-ownership: /cert-patch"
    take-ownership /cert-patch
  fi
fi