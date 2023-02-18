#!/bin/sh

if [[ -n "$DEBUG" ]]; then
  echo "=========================!!!!!!!!=============================="
  echo "            I'm sleeping. Make yourself at home!"
  echo "=========================!!!!!!!!=============================="

  while :
  do
    sleep 10
  done
fi

export LC_ALL=zh_CN.UTF-8

# 运行应用的用户的Home目录 https://github.com/jlesage/docker-baseimage-gui#the-home-variable
export HOME=$USER_HOME

# 表示应用已初始化的文件
FILE_INITIALIZED="/app/.mdcx_initialized"
FILE_INITIALIZED_INSIDE="/tmp/.mdcx_initialized"

FILE_PIP_REQ="/app/requirements.txt"

PYTHON_VERSION=$(python3 -V)
echo "🐍 Python版本: $PYTHON_VERSION"

cd /app

if [ -f "${FILE_INITIALIZED}" -a -f "${FILE_INITIALIZED_INSIDE}" ]; then
  echo "✅ 应用已初始化"
else
  echo "⏳ 初始化应用..."
  if [ -f "${FILE_PIP_REQ}" ]; then

    # 如果指定了PyQt5版本
    if [ -n "$PYQT5_VERSION" ]; then
      echo "ℹ️ 设置PyQt5版本为 $PYQT5_VERSION"
      cp requirements.txt requirements.txt.bak
      sed -i -e "s/PyQt5==[0-9.]\+/PyQt5==$PYQT5_VERSION/" requirements.txt
    fi

    DEFAULT_MIRROR="https://pypi.doubanio.com/simple"
    PYPI_MIRROR=${PYPI_MIRROR:-${DEFAULT_MIRROR}}
    echo "PYPI_MIRROR: $PYPI_MIRROR"

    python3 -m pip install \
      --verbose --user --no-cache-dir \
      -r requirements.txt \
      -i $PYPI_MIRROR
  else
    echo "❌ 找不到 ${FILE_PIP_REQ} ，请将MDCx应用目录映射到容器的 /app 目录，然后重启容器"
    exit 404
  fi
fi

# 创建标记文件
if [ ! -f "$FILE_INITIALIZED" ]; then
  touch ${FILE_INITIALIZED}
fi
if [ ! -f "$FILE_INITIALIZED_INSIDE" ]; then
  touch ${FILE_INITIALIZED_INSIDE}
fi

echo "🚀 启动应用..."

python3 MDCx_Main.py

