#!/bin/bash

# 脚本说明: 当使用源码部署时，使用该脚本自动完成更新源码的处理。

# DEV:
# - gui-base/update-src.sh
# - webtop-base/update-src.sh
# - webtop-base/rootfs-src/app-assets/scripts/update-src.sh
# 除了.env提示不同外，其余部分基本相同。
# webtop-base/rootfs-src/app-assets/scripts/update-src.sh 中 appPath=/app; 没有restart容器处理。

if [ ! -f ".env" ]; then
  echo "⚠️ 当前目录缺少文件 .env。示例文件：https://github.com/northsea4/mdcx-docker/blob/main/webtop-base/.env.sample"
  # exit 1
else
  . .env
fi

# 检查是否有jq命令
if ! command -v jq &> /dev/null
then
  echo "❌ 请先安装jq命令！参考：https://command-not-found.com/jq"
  exit 1
fi


FILE_INITIALIZED=".mdcx_initialized"

# 应用版本
appVersion=0

# 源码存放目录
appPath="/app"

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -p|--path|--src)
      appPath="$2"
      shift 2
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
  echo "--dry                     只检查，不更新"
  echo "-h, --help                显示帮助信息"
  exit 0
fi

generate_app_version() {
  local published_at="$1"

  # 去除非数字字符
  published_at=$(echo "$published_at" | tr -dc '0-9')

  # 取前8位数字作为年月日，前缀为d
  echo "d${published_at:0:8}"
}

find_release_by_tag_name() {
  local repo=$1
  local target_tag_name=$2
  
  local url="https://api.github.com/repos/${repo}/releases"

  # echo "URL: $url"

  local target_release=""

  let found=false
  local page=1
  while true; do
    local response=$(curl -s "${url}?per_page=100&page=${page}")
    if [[ -z "$response" ]]; then
      break
    fi

    local releases=$(printf '%s' $response | jq -c '.[]')
    for release in $releases; do
      tag_name=$(printf '%s' $release | jq -r '.tag_name')
      if [[ "$tag_name" == "$target_tag_name" ]]; then
        found=true
        echo $release
        break
      fi
    done

    if [[ $found ]]; then
      break
    fi

    page=$((page + 1))
  done
}

# 获取指定仓库和tag_name的release，并解析得到release信息
# 返回json对象:
# {
#   "tag_name": "v1.0.0",
#   "published_at": "2022-01-01T00:00:00Z",
#   "release_version": "120220101",
#   "tar_url": "https://api.github.com/repos/sqzw-x/mdcx/tarball/daily_release",
#   "zip_url": "https://api.github.com/repos/sqzw-x/mdcx/zipball/daily_release"
# }
get_release_info() {
  local repo="$1"
  local tag_name="$2"

  # echo "⏳ 正在获取仓库 ${repo} 中 tag_name=${tag_name} 的release..."
  local release=$(find_release_by_tag_name "$repo" "$tag_name")

  if [[ -z "$release" ]]; then
    echo "❌ 找不到 tag_name=${tag_name} 的release！"
    return 1
  fi

  tag_name=$(printf '%s' $release | jq -r '.tag_name')
  if [[ -z "$tag_name" ]]; then
    echo "❌ 找不到 tag_name！"
    return 1
  fi

  published_at=$(printf '%s' $release | jq -r '.published_at')
  if [[ -z "$published_at" ]]; then
    echo "❌ 找不到 published_at！"
    return 1
  fi

  release_version=$(generate_app_version "$published_at")

  tar_url=$(printf '%s' $release | jq -r '.tarball_url')
  if [[ -z "$tar_url" ]]; then
    echo "❌ 从请求结果获取源码压缩包文件下载链接失败！"
    return 1
  fi

  zip_url=$(printf '%s' $release | jq -r '.zipball_url')
  if [[ -z "$zip_url" ]]; then
    echo "❌ 从请求结果获取源码压缩包文件下载链接失败！"
    return 1
  fi

  # 构建一个json对象
  local data="{
    \"tag_name\": \"${tag_name}\",
    \"published_at\": \"${published_at}\",
    \"release_version\": \"${release_version}\",
    \"tar_url\": \"${tar_url}\",
    \"zip_url\": \"${zip_url}\"
  }"
  echo $data
  return 0
}

appPath=$(echo "$appPath" | sed 's:/*$::')

if [[ -n "${appPath}" ]]; then
  if [[ ! -d "${appPath}" ]]; then
    echo "⚠️ $appPath 不存在，现在创建"
    mkdir -p $appPath
  else
    echo "✅ $appPath 已经存在"
  fi
else
  echo "❌ 应用源码目录参数不能为空！"
  exit 1
fi

REPO="sqzw-x/mdcx"
TAG_NAME="daily_release"

info=$(get_release_info "$REPO" "$TAG_NAME")
if [[ $? -ne 0 ]]; then
  echo "❌ 获取仓库 ${REPO} 中 tag_name=${TAG_NAME} 的release信息失败！"
  exit 1
else
  echo "✅ 获取仓库 ${REPO} 中 tag_name=${TAG_NAME} 的release信息成功！"
fi
echo $info | jq
# exit 0

# 发布时间
published_at=$(printf '%s' $info | jq -r ".published_at")
echo "📅 发布时间: $published_at"

# 版本号
release_version=$(printf '%s' $info | jq -r ".release_version")
echo "🔢 版本号: $release_version"

# 源码链接
file_url=$(printf '%s' $info | jq -r ".tar_url")
echo "🔗 下载链接: $file_url"


if [[ -z "$file_url" ]]; then
  echo "❌ 从请求结果获取下载链接失败！"
  exit 1
fi

if [[ -n "$dry" ]]; then
  exit 0
fi

tar_path="$release_version.tar.gz"

if [[ -n "$verbose" ]]; then
  curl -o $tar_path $file_url -L
else
  curl -so $tar_path $file_url -L
fi

if [[ $? -ne 0 ]]; then
  echo "❌ 下载源码压缩包失败！"
  exit 1
fi

echo "✅ 下载成功"
echo "⏳ 开始解压..."

# 解压新的源码到app目录
tar -zxvf $tar_path -C $appPath --strip-components 1
# 删除压缩包
rm -f $tar_path
echo "✅ 源码已覆盖到 $appPath"

if [ -f ".env.versions" ]; then
  echo "✅ 更新 .env.versions MDCX_APP_VERSION=$release_version"
  sed -i -e "s/MDCX_APP_VERSION=[0-9.]\+/MDCX_APP_VERSION=$release_version/" .env.versions
fi

if [ -f ".env" ]; then
  echo "✅ 更新 .env APP_VERSION=$release_version"
  sed -i -e "s/APP_VERSION=[0-9.]\+/APP_VERSION=$release_version/" .env
fi

echo "ℹ️ 删除标记文件 $appPath/$FILE_INITIALIZED"
rm -f "$appPath/$FILE_INITIALIZED"

echo "🎉 Enjoy~"