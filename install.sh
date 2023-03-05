#!/bin/bash

# 检查是否有unrar命令
if ! command -v unrar &> /dev/null
then
    echo "❌ 未找到unrar命令，请先安装unrar命令。"
    exit 1
fi

OS=$(uname)
FILE_INITIALIZED=".mdcx_initialized"

replace_in_file() {
  if [ "$OS" = 'Darwin' ]; then
    # for MacOS
    sed -i '' -r -e "$1" "$2"
  else
    # for Linux and Windows
    sed -i'' -r -e "$1" "$2"
  fi
}

#询问用户选择的模版
echo "📖 下面请你回答几个问题，以完成MDCx Docker版的安装。"
echo ""
echo "❓ 请选择容器部署模版（输入数字进行选择）："
echo " 1) mdcx-builtin-gui-base      轻量版，内置编译版应用，通过网页使用"
echo " 2) mdcx-builtin-webtop-base   重量版，内置编译版应用，通过网页和远程桌面使用"
echo " 3) mdcx-src-gui-base          轻量版，自部署源码，通过网页使用"
echo " 4) mdcx-src-webtop-base       重量版，自部署源码，通过网页和远程桌面使用"

read -p "📌 请输入数字（1-4）: " TEMPLATE_NUM

case $TEMPLATE_NUM in
  1)
    TEMPLATE_NAME="mdcx-builtin-gui-base"
    ;;
  2)
    TEMPLATE_NAME="mdcx-builtin-webtop-base"
    ;;
  3)
    TEMPLATE_NAME="mdcx-src-gui-base"
    ;;
  4)
    TEMPLATE_NAME="mdcx-src-webtop-base"
    ;;
  *)
    echo "无效的输入！请输入数字（1-4）."
    exit 1
    ;;
esac

echo "📝 您选择的模版为：$TEMPLATE_NUM) $TEMPLATE_NAME"
echo ""

if [[ "$TEMPLATE_NAME" == *"gui-base"* ]]; then
  BASE=gui
else
  BASE=webtop
fi

if [[ "$TEMPLATE_NAME" == *"mdcx-src"* ]]; then
  TYPE=src
else
  TYPE=builtin
fi


#拼接模版文件下载链接
DOWNLOAD_URL="https://github.com/northsea4/mdcx-docker/releases/download/latest/template-$TEMPLATE_NAME.zip"

echo "🔗 模版文件下载链接：$DOWNLOAD_URL"
echo ""


# 询问用户目录名称，默认为 `mdcx-docker`
echo "选择一个目录作为本docker项目的根目录(存放应用或容器的相关数据)，可以是目录路径或目录名称。"
read -p "❓ 请输入目录名称（默认为 mdcx-docker）：" DIR_NAME
DIR_NAME=${DIR_NAME:-mdcx-docker}

# 检查目录是否已存在
while [ -d "$DIR_NAME" ]; do
  read -p "❌ 目录已存在，请输入其他目录名称：" DIR_NAME
done

# 下载zip文件并保存为随机文件名
RANDOM_NAME=$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9-_\$' | fold -w 20 | sed 1q)
ZIP_FILE="${RANDOM_NAME}.zip"
curl -o "$ZIP_FILE" "$DOWNLOAD_URL" -L

# 创建以文件名为名称的目录并解压zip文件
mkdir "$RANDOM_NAME"
unzip "$ZIP_FILE" -d "$RANDOM_NAME"

# 移动mdcx-docker目录并重命名为用户输入的目录名称
mv "$RANDOM_NAME/mdcx-docker" ./"$DIR_NAME"
# 删除临时目录和zip文件
rm -rf "$RANDOM_NAME"
rm "$ZIP_FILE"

# 进入用户输入的目录名称
cd "$DIR_NAME"

source .env

USER_ID=$(id -u)
GROUP_ID=$(id -g)
# 不同模版使用不同的环境变量名称
if [[ "$BASE" == "gui" ]]; then
  USER_ID_KEY="USER_ID"
  GROUP_ID_KEY="GROUP_ID"
else
  USER_ID_KEY="PUID"
  GROUP_ID_KEY="PGID"
fi

echo ""
echo "❓ 请输入${USER_ID_KEY}（容器使用的UID），默认为$(id -u)"
read -p "${USER_ID_KEY}: " USER_ID
USER_ID=${USER_ID:-$(id -u)}
# echo "📝 你输入的${USER_ID_KEY}为：$USER_ID"

echo ""
echo "❓ 请输入${GROUP_ID_KEY}（容器使用的GID），默认为$(id -g)"
read -p "${GROUP_ID_KEY}: " GROUP_ID
GROUP_ID=${GROUP_ID:-$(id -g)}
# echo "📝 你输入的${GROUP_ID_KEY}为：$GROUP_ID"


# 不同的模版使用不同的端口环境变量名称
if [[ "$BASE" == "gui" ]]; then
  echo ""
  echo "❓ 请输入WEB访问端口号， 默认为5800"
  read -p "WEB_PORT: " WEB_PORT
  WEB_PORT=${WEB_PORT:-5800}
  # echo "📝 你输入的WEB访问端口号为：$WEB_PORT"

  echo ""
  echo "❓ 请输入VNC端口号， 默认为5900"
  read -p "VNC_PORT: " VNC_PORT
  VNC_PORT=${VNC_PORT:-3389}
  # echo "📝 你输入的VNC_PORT端口号为：$VNC_PORT"
else
  echo ""
  echo "❓ 请输入WEB访问端口号， 默认为3000"
  read -p "WEB_PORT: " WEB_PORT
  WEB_PORT=${WEB_PORT:-3000}
  # echo "📝 你输入的WEB访问端口号为：$WEB_PORT"

  echo ""
  echo "❓ 请输入RDP访问端口号， 默认为3389"
  read -p "RDP_LISTEN_PORT: " RDP_LISTEN_PORT
  RDP_LISTEN_PORT=${RDP_LISTEN_PORT:-3389}
  # echo "📝 你输入的RDP访问端口号为：$RDP_LISTEN_PORT"
fi


echo ""
while true; do
    read -p "❓ 请输入需要映射的影片目录，格式为/path/to/movies:/movies，留空则跳过： " MOVIE_DIR
    if [ -z "$MOVIE_DIR" ]; then
        break
    elif ! echo "$MOVIE_DIR" | grep -qE '^[^:]+:[^:]+$'; then
        echo "❌ 错误：输入格式不正确，请按格式输入"
        continue
    fi
    VOLUMES="$VOLUMES\n      - $MOVIE_DIR"
done


# 展示用户所输入的信息，并询问确认信息是否正确
echo ""
echo "📝 您输入的信息如下："
echo "🔘 $USER_ID_KEY: $USER_ID"
echo "🔘 $GROUP_ID_KEY: $GROUP_ID"

# 根据不同的模版，展示不同的端口信息
if [[ "$BASE" == "gui" ]]; then
  echo "🔘 WEB_PORT: $WEB_PORT"
  echo "🔘 VNC_PORT: $VNC_PORT"
else
  echo "🔘 WEB_PORT: $WEB_PORT"
  echo "🔘 RDP_LISTEN_PORT: $RDP_LISTEN_PORT"
fi


if [ -z "$VOLUMES" ]; then
  echo "🔘 映射目录：没有指定"
else
  echo "🔘 映射目录："
  echo -e "${VOLUMES[*]}\n"
fi


echo ""
read -p "❓ 确认信息是否填写正确（yes/y确认，no/n退出）：" CONFIRMED

if [[ "$CONFIRMED" =~ ^[nN](o)?$ ]]; then
  echo "⚠️ 操作已取消"
  exit 0
fi


echo "⏳ 替换环境变量..."
# 根据不同的模版，替换不同的环境变量名称
if [[ "$BASE" == "gui" ]]; then
  replace_in_file "s/USER_ID=[0-9]+/USER_ID=$USER_ID/g" .env
  replace_in_file "s/GROUP_ID=[0-9]+/GROUP_ID=$GROUP_ID/g" .env
else
  replace_in_file "s/PUID=[0-9]+/PUID=$USER_ID/g" .env
  replace_in_file "s/PGID=[0-9]+/PGID=$GROUP_ID/g" .env
fi


# 根据不同的模版，替换不同的端口信息
if [[ "$BASE" == "gui" ]]; then
  replace_in_file "s/WEB_PORT=[0-9]+/WEB_PORT=$WEB_PORT/g" .env
  replace_in_file "s/VNC_PORT=[0-9]+/VNC_PORT=$VNC_PORT/g" .env
else
  replace_in_file "s/WEB_PORT=[0-9]+/WEB_PORT=$WEB_PORT/g" .env
  replace_in_file "s/RDP_LISTEN_PORT=[0-9]+/RDP_LISTEN_PORT=$RDP_LISTEN_PORT/g" .env
fi

echo "✅ 替换环境变量完成"

echo "⏳ 替换挂载卷..."
# $VOLUMES不为空时才进行替换
if [[ -n "$VOLUMES" ]]; then
  replace_in_file "s|# VOLUMES_REPLACEMENT|$VOLUMES|" docker-compose.yml
  echo "✅ 替换挂载卷完成"
else
  echo "⚠️ 你没有指定映射影片目录，你可以之后在docker-compose.yml中手动添加。"
fi

downloadSrc() {
  local _content=$(curl -s "https://api.github.com/repos/anyabc/something/releases/latest")

  local archiveUrl=$(echo $_content | grep -oi 'https://[a-zA-Z0-9./?=_%:-]*MDCx-py-[a-z0-9]\+.[a-z]\+')

  if [[ -z "$archiveUrl" ]]; then
    echo "❌ 获取下载链接失败！"
    exit 1
  fi

  local archiveFullName=$(echo $archiveUrl | grep -oi 'MDCx-py-[a-z0-9]\+.[a-z]\+')
  local archiveExt=$(echo $archiveFullName | grep -oi '[a-z]\+$')
  local archiveVersion=$(echo $archiveFullName | sed 's/MDCx-py-//g' | sed 's/\.[^.]*$//')
  local archivePureName=$(echo $archiveUrl | grep -oi 'MDCx-py-[a-z0-9]\+')

  echo "🔗 下载链接：$archiveUrl"
  echo "ℹ️ 压缩包全名：$archiveFullName"
  echo "ℹ️ 压缩包文件名：$archivePureName"
  echo "ℹ️ 压缩包后缀名：$archiveExt"

  echo "ℹ️ 已发布版本：$archiveVersion"

  archivePath="$archivePureName.rar"

  curl -o $archivePath $archiveUrl -L

  echo "✅ 下载成功"
  echo "⏳ 开始解压..."

  local appPath="./app"
  mkdir -p $appPath

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
}

# 如果是src版，则需要下载源码
if [[ "$TYPE" == "src" ]]; then
  echo ""
  echo "⏳ 下载源码..."
  downloadSrc
fi

# 询问输入容器名称
echo ""
echo "❓ 请输入容器名称（默认：${MDCX_CONTAINER_NAME}）"
read -p "容器名称：" CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-$MDCX_CONTAINER_NAME}

echo "⏳ 替换容器名称..."
replace_in_file "s/MDCX_CONTAINER_NAME=.*/MDCX_CONTAINER_NAME=$CONTAINER_NAME/g" .env
echo "✅ 替换容器名称完成"

echo ""
read -p "❓ 是否运行容器？[y/n] " RUN_CONTAINER
if [[ "$RUN_CONTAINER" =~ ^[Yy](es)?$ ]]; then
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo "✅ 容器已经成功运行"
    else
        echo "❌ 容器启动失败，请检查错误日志"
        exit 1
    fi
fi