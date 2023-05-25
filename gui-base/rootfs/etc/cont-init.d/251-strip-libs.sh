#!/bin/sh

# Synology DSM 7.1.1-42962 Update 5
# Docker 20.10.3-1308
# arm64

# https://github.com/northsea4/mdcx-docker/issues/18

# ImportError: libQt5Core.so.5: cannot open shared object file: No such file or directory

echo "========================= strip libQt5Core =============================="

if [ "$STRIP_LIBQT5CORE" != "true" ]; then
  echo "🔧 环境变量STRIP_LIBQT5CORE不为true，跳过strip libQt5Core"
  exit 0
fi


ARCH=$(uname -m)

QT5CORE_PATH="/usr/lib/$ARCH-linux-gnu/libQt5Core.so.5"
# 备份文件路径
QT5CORE_PATH_BAK="/home/libQt5Core.so.5.bak"

if [ ! -f "$QT5CORE_PATH" ]; then
  echo "❌ $QT5CORE_PATH 不存在！"
  exit 1
fi

# 如果不存在备份文件，则进行备份和strip处理
if [ ! -f "$QT5CORE_PATH_BAK" ]; then
  cp $QT5CORE_PATH $QT5CORE_PATH_BAK
  # 然后进行strip处理
  strip --remove-section=.note.ABI-tag $QT5CORE_PATH
  if [ $? -ne 0 ]; then
    echo "❌ strip处理失败！"
    rm -f $QT5CORE_PATH_BAK
    exit 1
  fi
  echo "✅ 已对 $QT5CORE_PATH 进行strip处理"
  echo "🔧 备份文件路径: $QT5CORE_PATH_BAK"
else
  echo "🔧 $QT5CORE_PATH 已做strip处理"
fi