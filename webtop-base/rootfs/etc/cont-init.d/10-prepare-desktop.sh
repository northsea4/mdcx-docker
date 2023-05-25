#!/usr/bin/with-contenv bash

# 需要使用`/usr/bin/with-contenv`来获取容器环境变量
# https://github.com/just-containers/s6-overlay#container-environment
# If you want your custom script to have container environments available: 
# you can use the with-contenv helper, which will push all of those into your execution environment, 
# for example:
# #!/usr/bin/with-contenv bash
# echo "PUID: $PUID, PGID: $PGID"

# 需要注意的是，当使用`/usr/bin/with-contenv`时，直接执行 `/path/to/script.sh` ，会改变`$HOME`为`/root`，
# 这会导致一些奇怪的问题，比如python应用无法正常运行。
# 对于本脚本，使用`#!/usr/bin/with-contenv bash`头部是可行的。
# 但对于`run-src.sh`，则不可行，具体可以到`run-src.sh`中查看。

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