#!/usr/bin/with-contenv bash

# 需要使用`/usr/bin/with-contenv`来获取容器环境变量
# https://github.com/just-containers/s6-overlay#container-environment
# If you want your custom script to have container environments available: 
# you can use the with-contenv helper, which will push all of those into your execution environment, 
# for example:
# #!/usr/bin/with-contenv bash
# echo "PUID: $PUID, PGID: $PGID"

prepare() {
  while true
  do
    if [ -d "/config/Desktop" -a -d "/app-assets/desktop" ]; then
      echo "Desktop is ready, copy desktop files..."
      
      chown -R $PUID:$PGID /app-assets
      chmod -R 755 /app-assets/

      cp -p /app-assets/desktop/* /config/Desktop/
      break
    else
      # echo "Desktop is not ready"
      sleep 5
    fi
  done
}

prepare &