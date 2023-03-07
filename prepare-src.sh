#!/bin/sh

# 脚本说明：下载应用源码并解压到指定的目录(通过`context`指定)下的`.mdcx_src`目录
# 一般只用于构建镜像流程，普通用户可以忽略。

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    --context)
      context="$2"
      shift
      shift
      ;;
    --verbose)
      verbose=1
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

if [[ -z "$context" ]]; then
  echo "❌ context is required!"
  exit 1
fi

if [[ ! -d "$context" ]]; then
  echo "❌ Dir $context is not exist!"
  exit 1
fi

cd $context


echo "ℹ️ 将从发布仓库下载源码进行构建"

_content=$(curl -s "https://api.github.com/repos/anyabc/something/releases/latest")

archiveUrl=$(echo $_content | grep -oi 'https://[a-zA-Z0-9./?=_%:-]*MDCx-py-[a-z0-9]\+.[a-z]\+')

# TODO github workflow里竟然会有比较大的概率获取失败
if [[ -z "$archiveUrl" ]]; then
  echo "❌ 获取下载链接失败！"
  exit 1
fi

archiveFullName=$(echo $archiveUrl | grep -oi 'MDCx-py-[a-z0-9]\+.[a-z]\+')
archiveExt=$(echo $archiveFullName | grep -oi '[a-z]\+$')
archiveVersion=$(echo $archiveFullName | sed 's/MDCx-py-//g' | sed 's/\.[^.]*$//')
archivePureName=$(echo $archiveUrl | grep -oi 'MDCx-py-[a-z0-9]\+')

if [[ -n "$verbose" ]]; then
  echo "🔗 下载链接: $archiveUrl"
  echo "ℹ️ 压缩包全名: $archiveFullName"
  echo "ℹ️ 压缩包文件名: $archivePureName"
  echo "ℹ️ 压缩包后缀名: $archiveExt"
fi
echo "ℹ️ 已发布版本: $archiveVersion"

if [[ -z "$archiveUrl" ]]; then
  echo "❌ 从请求结果获取下载链接失败！"
  exit 1
fi

echo "⏳ 下载文件..."

archivePath="$archivePureName.rar"
srcDir=".mdcx_src"

if [[ -n "$verbose" ]]; then
  curl -o $archivePath $archiveUrl -L
else
  curl -so $archivePath $archiveUrl -L
fi

echo "✅ 下载成功"
echo "⏳ 开始解压..."

UNRAR_PATH=$(which unrar)
if [[ -z "$UNRAR_PATH" ]]; then
  echo "❌ 没有unrar命令！"
  exit 1
else
  rm -rf $srcDir
  # 解压
  unrar x -o+ $archivePath
  mkdir -p $srcDir
  cp -rfp $archivePureName/* $srcDir
  # 删除压缩包
  rm -f $archivePath
  # 删除解压出来的目录
  rm -rf $archivePureName
  echo "✅ 源码已解压到 $srcDir"
fi

if [ -n "$GITHUB_ACTIONS" ]; then
  echo "APP_VERSION=$archiveVersion" >> $GITHUB_OUTPUT
fi
