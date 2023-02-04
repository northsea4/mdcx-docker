#!/bin/bash
. .env.versions

imageVersion=""


while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -iv|--image-version)
      imageVersion="$2"
      shift
      shift
      ;;  
    --src)
      srcDir="$2"
      shift
      shift
      ;;
    --dry)
      dry=1
      shift
      ;;
    -od|--only-download)
      onlyDownload=1
      shift
      ;;
    --push)
      push=1
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
  echo "脚本功能：stainless403/mdcx镜像的构建、上传等处理"
  echo ""
  echo "参数说明："
  echo "-iv, --image-version    镜像版本号。默认取用应用版本"
  echo "--src                   MDCx源码路径。该参数暂未实现！"
  echo "                        目前如果指定了任意值，实际数值都是 .mdcx_src。所以如果是手动下载源码进行构建，请将源码目录命名为 .mdcx_src。"
  echo "                        不指定时，将会从发布仓库下载，并忽略app-version参数"
  echo "-od, --only-download    只下载源码，不进行构建"
  echo "--push                  构建后推送到Docker Hub，默认不推送"
  echo "--dry                   演示模式，不做实际处理"
  echo "-h, --help              显示帮助信息"
  echo "--verbose               显示详细信息"
  echo ""
  echo "作者：生瓜太保"
  echo "版本：20230203"
  exit 0
fi

if [[ -n "$srcDir" ]]; then

  if [ ! -d "$srcDir" ]; then
    echo "❌ 指定了MDCx源码路径 $src，但这个路径不存在！"
    exit 1
  fi

  echo "ℹ️  将以 $srcDir 作为MDCx源码目录进行构建"
  if [[ ! -f "$srcDir/setup.py" ]]; then
    echo "❌ 在源码目录下不存在 setup.py 文件！"
    exit 1
  fi

  # 'CFBundleShortVersionString': "20230201",
  appVersion=$(cat $srcDir/setup.py | grep -oi 'CFBundleShortVersionString.: "[a-z0-9]\+' | grep -oi '[a-z0-9]\+$')
  echo "ℹ️  检测到 $srcDir 里的应用版本为 $appVersion"

else

  echo "ℹ️  将从发布仓库下载源码进行构建"

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

  appVersion=$archiveVersion
fi

if [[ -n "$dry" ]]; then
  exit 0
fi

if [[ -n "$archiveUrl" ]]; then
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
  else
    rm -rf $srcDir
    # 解压
    unrar x -o+ $archivePath
    # 暂时没发现unrar有类似tar的strip-components这样的参数，
    # 所以解压时会带有项目根目录，需要将目录里的文件复制出来
    mkdir -p $srcDir
    cp -rfp $archivePureName/* $srcDir
    # 删除压缩包
    rm -f $archivePath
    # 删除解压出来的目录
    rm -rf $archivePureName
    echo "✅ 源码已解压到 $srcDir"
  fi
fi

if [[ -n "$archiveUrl" ]]; then
  if [[ -n "$onlyDownload" ]]; then
    exit 0
  fi
fi

echo "⏳ 构建镜像..."
docker build . \
  --build-arg APP_VERSION=$appVersion \
  -f Dockerfile.mdcx \
  -t stainless403/mdcx:dev \
  -t stainless403/mdcx:latest

echo "✅ 镜像构建完成"

if [[ -z "$imageVersion" ]]; then
  imageVersion="$appVersion"
fi

echo "ℹ️  镜像版本为 $imageVersion"

echo "ℹ️  设置镜像tag..."
docker tag stainless403/mdcx:latest stainless403/mdcx:$imageVersion


echo "ℹ️  更新 .env.versions MDCX_IMAGE_VERSION=$imageVersion"
sed -i -e "s/MDCX_IMAGE_VERSION=[0-9.]\+/MDCX_IMAGE_VERSION=$imageVersion/" .env.versions

echo "ℹ️  更新 .env.versions BUILTIN_MDCX_VERSION=$appVersion"
sed -i -e "s/BUILTIN_MDCX_VERSION=[0-9.]\+/BUILTIN_MDCX_VERSION=$appVersion/" .env.versions

if [[ -n "$push" ]]; then
  echo "⏳ 推送镜像..."
  if [[ -n "$verbose" ]]; then
    docker push stainless403/mdcx:latest
    docker push stainless403/mdcx:$imageVersion
  else
    docker push -q stainless403/mdcx:latest
    docker push -q stainless403/mdcx:$imageVersion
  fi
  
  echo "✅ 已完成推送镜像"
else
  echo "ℹ️  可以使用以下命令推送镜像"
  echo "docker push -q stainless403/mdcx:latest"
  echo "docker push -q stainless403/mdcx:$imageVersion"
fi