#!/bin/bash

. .env.versions

appVersion=$MDCX_IMAGE_VERSION

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -cv|--current-version)
      appVersion="$2"
      shift
      ;;
    --dry)
      dry=1
      shift
      ;;
    -h|--help)
      help=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ -n "$help" ]; then
  echo "脚本功能：检查新版本应用，自动更新应用。"
  echo ""
  echo "示例-检查并更新：./update-mdcx-base.sh"
  echo "示例-指定旧版本：./update-mdcx-base.sh -cv 20230131"
  echo "示例-仅检查不更新：./update-mdcx-base.sh --dry"
  echo ""
  echo "参数说明："
  echo "-cv, --current-version    本地应用版本号，不指定则从 .env.versions 文件中获取"
  echo "--dry                     只检查，不更新"
  echo " -h, --help               显示帮助信息"
  echo ""
  echo "作者：生瓜太保"
  echo "版本：20230203"
  exit 0
fi

compareVersion () {
  if [[ $1 == $2 ]]
  then
    return 0
  fi
  local IFS=.
  local i ver1=($1) ver2=($2)
  # fill empty fields in ver1 with zeros
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
  do
    ver1[i]=0
  done
  for ((i=0; i<${#ver1[@]}; i++))
  do
    if [[ -z ${ver2[i]} ]]
    then
      # fill empty fields in ver2 with zeros
      ver2[i]=0
    fi
    if ((10#${ver1[i]} > 10#${ver2[i]}))
    then
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]}))
    then
      return 2
    fi
  done
  return 0
}

# 临时存放应用源码的目录
DIR_APP_RAW="app-raw"
if [[ -n "$dry" ]]; then
  rm -rf $DIR_APP_RAW
fi

DIR_APP="app"

CONTENT=$(curl -s "https://api.github.com/repos/anyabc/something/releases/latest")

URL=$(echo $CONTENT | grep -oi 'https://[a-zA-Z0-9./?=_%:-]*MDCx-py-[a-z0-9]\+.[a-z]\+')

if [[ -z "$URL" ]]; then
  echo "❌ 获取新版下载链接失败！"
  exit
fi

echo "🔗 下载链接：$URL"

FILENAME=$(echo $URL | grep -oi 'MDCx-py-[a-z0-9]\+.[a-z]\+')
EXTENSION=$(echo $FILENAME | grep -oi '[a-z]\+$')
VERSION=$(echo $FILENAME | sed 's/MDCx-py-//g' | sed 's/.[a-z]\+//g')
PURE_FILENAME=$(echo $URL | grep -oi 'MDCx-py-[a-z0-9]\+')

echo "⭕️ 文件名：$PURE_FILENAME"
echo "⭕️ 后缀名：$EXTENSION"
echo "⭕️ 最新版本：$VERSION"
echo "⭕️ 本地版本：$appVersion"

# exit

compareVersion $VERSION $appVersion
case $? in
  0) op='=';;
  1) op='>';;
  2) op='<';;
esac

if [[ $op == '>' ]]; then
  echo "🆕 已发布的最新版本 较新于 本地版本"

  if [[ -n "$dry" ]]; then
    exit 0
  fi

  mkdir -p ./$DIR_APP_RAW
  cd ./$DIR_APP_RAW

  # echo "✅ 清空 ./$DIR_APP_RAW 目录"
  # rm -rf ./$DIR_APP_RAW/*

  echo "⭕️ 下载新版..."
  # TODO 暂时只考虑rar格式
  curl -o $VERSION.rar $URL -L
  echo "✅ 下载成功。开始解压到 ./$DIR_APP_RAW 目录"

  UNRAR_PATH=$(which unrar)
  if [[ -z "$UNRAR_PATH" ]]; then
    echo "❌ 没有unrar命令！"
  else
    # 解压
    unrar x -o+ $VERSION.rar
    # 暂时没发现unrar有类似tar的stip-components这样的参数，
    # 所以解压时会带有项目根目录，需要将目录里的文件复制出来
    cp -rfp $PURE_FILENAME/* .
    # 删除压缩包
    rm -f $VERSION.rar
    # 删除解压出来的目录
    rm -rf $PURE_FILENAME
    echo "✅ 解压成功！MDCx源码已解压到 $DIR_APP_RAW"

    echo "✅ 更新 .env.versions MDCX_IMAGE_VERSION"
    sed -i -e "s/MDCX_IMAGE_VERSION=[0-9.]\+/MDCX_IMAGE_VERSION=/" .env.versions
  fi
else
  if [[ $op == '<' ]]; then
    echo "🍵 本地版本 较新于 已发布的最新版本"
  else
    echo "🍵 本地版本 已是最新版本"
  fi
fi