#!/bin/bash

. .env

### 脚本说明 ###
# 删除`已初始化`标记文件

# 表示应用已初始化的文件
FILE_INITIALIZED="./app/.mdcx_initialized"

echo "ℹ️  容器名称：$CONTAINER_NAME"

# 容器`$CONTAINER_NAME`名称取自.env文件
rm -f $FILE_INITIALIZED
echo "✅ 删除 $FILE_INITIALIZED"

echo "⏳ 重启容器$CONTAINER_NAME..."
docker restart $CONTAINER_NAME