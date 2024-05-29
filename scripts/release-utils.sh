#!/bin/sh

# 脚本说明：检查新版本

# 检查是否有jq命令
if ! command -v jq &> /dev/null
then
  echo "❌ 请先安装jq命令！参考：https://command-not-found.com/jq"
  exit 1
fi

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
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

generate_app_version() {
  local published_at="$1"

  # 去除非数字字符
  published_at=$(echo "$published_at" | tr -dc '0-9')
  
  # 取前8位数字作为年月日，前缀为1
  echo "1${published_at:0:8}"
}

find_release_by_tag_name() {
  local repo=$1
  local target_tag_name=$2
  
  local url="https://api.github.com/repos/${repo}/releases"

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
      local tag_name=$(printf '%s' $release | jq -r '.tag_name')
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

  echo "⏳ 正在获取仓库 ${repo} 中 tag_name=${tag_name} 的release..."
  local release=$(find_release_by_tag_name "$repo" "$tag_name")

  if [[ -z "$release" ]]; then
    echo "❌ 找不到 tag_name=${tag_name} 的release！"
    return 1

  local tag_name=(printf '%s' $release | jq -r '.tag_name')
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