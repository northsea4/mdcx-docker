#!/usr/bin/with-contenv bash

# 获取容器环境变量(如PYPI_MIRROR)，需要使用with-contenv。
# 但使用with-contenv，会改变`$HOME`为`/root`，导致莫名其妙的问题。
# 解决方法是，使用「bash 脚本路径」来执行脚本，即: bash /path/to/script.sh
if [ "$USER" != "root" -a "$HOME" = "/root" ]; then
  echo "❌ 请以「bash 脚本路径」方式执行脚本，即: bash $0"
  exit 1
fi

if [ -n "$DEBUG_CONTAINER" ]; then
  echo "=========================!!!!!!!!=============================="
  echo "            I'm sleeping. Make yourself at home!"
  echo "=========================!!!!!!!!=============================="

  while :
  do
    sleep 10
  done
fi

export LC_ALL=zh_CN.UTF-8

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
      --verbose --user \
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

# 如果发生错误
if [ $? -ne 0 ]; then
  echo "❌ 启动应用失败"
  # 删除`已初始化标记文件`
  rm -f ${FILE_INITIALIZED}
  rm -f ${FILE_INITIALIZED_INSIDE}

  if command -v konsole &> /dev/null; then
    # 打开konsole，显示错误信息
    message="启动应用失败！请打开一个新的Konsole窗口，执行命令: bash /app-assets/scripts/run-src.sh"
    konsole --new-tab --separate --hold -e "echo ${message}" --geometry 800x600
  fi
  exit 1
fi