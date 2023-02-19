#!/bin/sh

prepare() {
  while true
  do
    if [ -d "/config/Desktop" -a -d "/tmp/.desktop-files" ]; then
      echo "Desktop is ready, copy desktop files..."
      cp /tmp/.desktop-files/* /config/Desktop/
      break
    else
      # echo "Desktop is not ready"
      sleep 5
    fi
  done
}

prepare &