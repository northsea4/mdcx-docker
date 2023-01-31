#!/bin/bash

. .env

### 脚本说明 ###
# 删除`已初始化`标记文件

# 表示应用已初始化的文件
FILE_INITIALIZED="/.mdcx_initialized"

echo $CONTAINER_NAME

# 容器`$CONTAINER_NAME`名称取自.env文件
docker exec -it $CONTAINER_NAME rm $FILE_INITIALIZED