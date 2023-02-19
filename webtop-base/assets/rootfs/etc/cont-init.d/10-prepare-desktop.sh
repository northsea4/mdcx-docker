#!/bin/sh

prepare() {
  while true
  do
    if [ -d "/config/Desktop" -a -d "/.app-assets/desktop" ]; then
      echo "Desktop is ready, copy desktop files..."
      cp /.app-assets/desktop/* /config/Desktop/
      break
    else
      # echo "Desktop is not ready"
      sleep 5
    fi
  done
}

prepare &