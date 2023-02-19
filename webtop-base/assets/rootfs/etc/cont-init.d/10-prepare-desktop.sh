#!/bin/sh

prepare() {
  while true
  do
    if [ -d "/config/Desktop" -a -d "/usr/.desktop-files" ]; then
      echo "Desktop is ready, copy desktop files..."
      cp /usr/.desktop-files/* /config/Desktop/
      break
    else
      # echo "Desktop is not ready"
      sleep 5
    fi
  done
}

prepare &