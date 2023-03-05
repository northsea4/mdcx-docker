#!/bin/bash

FILE_INITIALIZED=".mdcx_initialized"

# 应用版本
appVersion=0

# 详细日志
verbose=1

# 默认强制更新
force=1

# 源码存放目录
appPath="/app"

if [[ ! -d "$appPath" ]]; then
   echo "❌ 应用源码不存在！"
  exit 1
fi


while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
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


if [ -n "$help" ]; then
  echo "脚本功能：更新自部署的应用源码"
  echo ""
  echo "示例-检查并更新:    $0"
  echo ""
  echo "参数说明："
  echo "--restart                 更新后重启容器，默认true。可选参数值: 1, 0; true, false"
  echo "--force                   强制更新。默认情况下当已发布版本较新于本地版本时才会更新。"
  echo "--dry                     只检查，不更新"
  echo "-h, --help                显示帮助信息"
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


if [[ -f "$appPath/setup.py" ]]; then
  # 'CFBundleShortVersionString': "20230201",
  appVersion=$(cat $appPath/setup.py | grep -oi 'CFBundleShortVersionString.: "[a-z0-9]\+' | grep -oi '[a-z0-9]\+$')
  echo "ℹ️ 从 $appPath/setup.py 检测到应用版本为 $appVersion"
else
  echo "❌ 应用源码目录下没有setup.py文件！"
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
archiveVersion=$(echo $archiveFullName | sed 's/MDCx-py-//g' | sed 's/\.[^.]*$//')
archivePureName=$(echo $archiveUrl | grep -oi 'MDCx-py-[a-z0-9]\+')

if [[ -n "$verbose" ]]; then
  echo " 下载链接：$archiveUrl"
  echo "ℹ️ 压缩包全名：$archiveFullName"
  echo "ℹ️ 压缩包文件名：$archivePureName"
  echo "ℹ️ 压缩包后缀名：$archiveExt"
fi
echo "ℹ️ 已发布版本：$archiveVersion"


compareVersion $archiveVersion $appVersion
case $? in
  0) op='=';;
  1) op='>';;
  2) op='<';;
esac

shouldUpdate=
if [[ $op == '>' ]]; then
  echo " 已发布的最新版本 较新于 本地版本"
  shouldUpdate=1
fi

if [[ -n "$force" ]]; then
  echo "ℹ️ 强制更新"
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
    cp -rfp $archivePureName/* $appPath
    # 删除压缩包
    rm -f $archivePath
    # 删除解压出来的目录
    rm -rf $archivePureName
    echo "✅ 源码已覆盖到 $appPath"

    echo "ℹ️ 删除标记文件 $appPath/$FILE_INITIALIZED"
    rm -f "$appPath/$FILE_INITIALIZED"

    echo "✅ 源码已更新成功！"
  fi
else
  if [[ $op == '<' ]]; then
    echo "ℹ️ 本地版本 较新于 已发布的最新版本"
  else
    echo "ℹ️ 本地版本 已是最新版本"
  fi
fi

echo "ℹ️ 按下任意键关闭窗口。"