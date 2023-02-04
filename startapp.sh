#!/bin/sh

# 表示应用已初始化的文件
FILE_INITIALIZED="/app/.mdcx_initialized"
FILE_INITIALIZED_INSIDE="/.mdcx_initialized_2"

FILE_PIP_REQ="/app/requirements.txt"

cd /app

if [[ -f "${FILE_INITIALIZED}" && -f "${FILE_INITIALIZED_INSIDE}" ]]; then
  echo "✅ 已初始化"
else
  echo "⏳ 初始化..."
  if [ -f "${FILE_PIP_REQ}" ]; then
    python3.9 -m pip install --no-cache-dir -r requirements.txt -i https://pypi.douban.com/simple
  else
    echo "❌ 找不到 ${FILE_PIP_REQ} ，请将MDCx应用目录映射到容器的 /app 目录，然后重启容器"
    exit
  fi
fi

# 创建标记文件
touch ${FILE_INITIALIZED}
touch ${FILE_INITIALIZED_INSIDE}

echo "🚀 启动..."

python3.9 MDCx_Main.py

