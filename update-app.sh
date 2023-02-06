#!/bin/bash

if [ ! -f ".env" ]; then
  echo "⚠️ 当前目录缺少文件 .env。示例文件：https://github.com/northsea4/mdcx-docker/blob/dev/.env.sample"
  echo 'TZ=Asia/Shanghai

APP_NAME=MDCx
APP_VERSION=20230204

# 应用窗口宽度
DISPLAY_WIDTH=1200
# 应用窗口高度
DISPLAY_HEIGHT=750

# 访问密码，如不需要，留空。如果有在公网远程访问的需求，建议设置
VNC_PASSWORD=

# 网页访问端口
WEB_LISTENING_PORT=5800
# VNC监听端口
VNC_LISTENING_PORT=5900

# 容器名称
CONTAINER_NAME=mdcx' > .env

  echo "ℹ️  已创建 .env 文件"
fi

if [ ! -f ".env.versions" ]; then
  echo "⚠️ 当前目录缺少文件 .env.versions。示例文件：https://github.com/northsea4/mdcx-docker/blob/dev/.env.versions"

  echo '# 本项目版本
PROJECT_VERSION=0.3.4

# stainless403/gui-base镜像版本
GUI_BASE_VERSION=0.2.1

# stainless403/mdcx-base镜像版本
MDCX_BASE_IMAGE_VERSION=0.2.6

# stainless403/mdcx镜像版本
MDCX_IMAGE_VERSION=20230204

# stainless403/mdcx内置MDCx版本
BUILTIN_MDCX_VERSION=20230204

# 本地自部署MDCx应用版本
MDCX_APP_VERSION=20230204' > .env.versions

  echo "ℹ️  已创建 .env.versions 文件"

fi

. .env
. .env.versions

FILE_INITIALIZED=".mdcx_initialized"

appVersion=$MDCX_APP_VERSION

appPath="./app"

restart=true

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -p|--path|--src)
      appPath="$2"
      shift
      shift
      ;;
    --restart)
      restart="$2"
      shift
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    --dry)
      dry=1
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

# echo "appPath: $appPath"
# echo "restart: $restart"
# echo "force: $force"
# echo "dry: $dry"
# echo "verbose: $verbose"
# echo "help: $help"
# exit


if [ -n "$help" ]; then
  echo "脚本功能：更新使用tainless403/mdcx-base部署的本地应用，如果没有安装过会自动安装。"
  echo ""
  echo "示例-检查并更新:    ./update-app.sh"
  echo "示例-指定应用目录:  ./update-app.sh --src /path/tp/mdcx-app"
  echo "示例-强制更新:  ./update-app.sh --force"
  echo ""
  echo "参数说明："
  echo "-p, --path, --src         本地应用目录路径，默认为 ./app"
  echo "--restart                 更新后重启容器，默认true。可选参数值: 1, 0; true, false"
  echo "--force                   强制更新。默认情况下当已发布版本较新于本地版本时才会更新。"
  echo "--dry                     只检查，不更新"
  echo "-h, --help                显示帮助信息"
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

appPath=$(echo "$appPath" | sed 's:/*$::')
isEmpty=0

if [[ -n "${appPath}" ]]; then
  if [[ ! -d "${appPath}" ]]; then
    echo "⚠️ $appPath 不存在，现在创建"
    mkdir $appPath
  else
    if [[ -f "$appPath/setup.py" ]]; then
      # 'CFBundleShortVersionString': "20230201",
      appVersion=$(cat $appPath/setup.py | grep -oi 'CFBundleShortVersionString.: "[a-z0-9]\+' | grep -oi '[a-z0-9]\+$')
      echo "ℹ️  从 $appPath/setup.py 检测到应用版本为 $appVersion"
    else
      isEmpty=1
      appVersion=0
      echo "ℹ️  本地应用版本: $appVersion"
    fi
  fi
else
  echo "❌ 应用源码目录不能为空！"
  exit 1
fi

_content=$(curl -s "https://api.github.com/repos/anyabc/something/releases/latest")

archiveUrl=$(echo $_content | grep -oi 'https://[a-zA-Z0-9./?=_%:-]*MDCx-py-[a-z0-9]\+.[a-z]\+')

if [[ -z "$archiveUrl" ]]; then
  echo "❌ 获取下载链接失败！"
  exit 1
fi

archiveFullName=$(echo $archiveUrl | grep -oi 'MDCx-py-[a-z0-9]\+.[a-z]\+')
archiveExt=$(echo $archiveFullName | grep -oi '[a-z]\+$')
archiveVersion=$(echo $archiveFullName | sed 's/MDCx-py-//g' | sed 's/.[a-z]\+//g')
archivePureName=$(echo $archiveUrl | grep -oi 'MDCx-py-[a-z0-9]\+')

if [[ -n "$verbose" ]]; then
  echo "🔗 下载链接：$archiveUrl"
  echo "ℹ️  压缩包全名：$archiveFullName"
  echo "ℹ️  压缩包文件名：$archivePureName"
  echo "ℹ️  压缩包后缀名：$archiveExt"
fi
echo "ℹ️  已发布版本：$archiveVersion"

# exit

compareVersion $archiveVersion $appVersion
case $? in
  0) op='=';;
  1) op='>';;
  2) op='<';;
esac

shouldUpdate=
if [[ $op == '>' ]]; then
  echo "🆕 已发布的最新版本 较新于 本地版本"
  shouldUpdate=1
fi

if [[ -n "$force" ]]; then
  echo "ℹ️  强制更新"
  shouldUpdate=1
fi

if [[ -n "$shouldUpdate" ]]; then

  if [[ -n "$dry" ]]; then
    exit 0
  fi

  archivePath="$archivePureName.rar"

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
  else
    # 解压
    unrar x -o+ $archivePath
    # 暂时没发现unrar有类似tar的strip-components这样的参数，
    # 所以解压时会带有项目根目录，需要将目录里的文件复制出来
    cp -rfp $archivePureName/* $appPath
    # 删除压缩包
    rm -f $archivePath
    # 删除解压出来的目录
    rm -rf $archivePureName
    echo "✅ 源码已覆盖到 $appPath"

    echo "✅ 更新 .env.versions MDCX_APP_VERSION=$archiveVersion"
    sed -i -e "s/MDCX_APP_VERSION=[0-9.]\+/MDCX_APP_VERSION=$archiveVersion/" .env.versions

    echo "✅ 更新 .env APP_VERSION=$archiveVersion"
    sed -i -e "s/APP_VERSION=[0-9.]\+/APP_VERSION=$archiveVersion/" .env

    echo "ℹ️  删除标记文件 $appPath/$FILE_INITIALIZED"
    rm -f "$appPath/$FILE_INITIALIZED"

    if [[ "$restart" == "1" || "$restart" == "true" ]]; then
      echo "⏳ 重启容器..."
      docker restart $CONTAINER_NAME
    else
      echo "ℹ️  执行以下命令重启容器"
      echo "docker restart $CONTAINER_NAME"
    fi
  fi
else
  if [[ $op == '<' ]]; then
    echo "ℹ️  本地版本 较新于 已发布的最新版本"
  else
    echo "ℹ️  本地版本 已是最新版本"
  fi
fi