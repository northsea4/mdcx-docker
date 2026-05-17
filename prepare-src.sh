#!/bin/sh

# 脚本说明：下载应用源码并解压到指定的目录(通过`context`指定)下的`.mdcx_src`目录
# 一般只用于构建镜像流程，普通用户可以忽略。
# UPDATE 2023-12-24 17:08:03 使用新的源码仓库:https://github.com/sqzw-x/mdcx
# UPDATE 2024-05-28 21:28:01 sqzw-x/mdcx目前基本只进行daily_release构建
# UPDATE 2026-03-29 20:46:30 dynamic repo

get_default_release_tag_by_repo() {
  local target_repo="$1"
  case "$target_repo" in
    sqzw-x/mdcx)
      echo "daily_release"
      ;;
    *)
      echo "latest"
      ;;
  esac
}

generate_app_version() {
  local published_at="$1"

  # 去除非数字字符
  published_at=$(echo "$published_at" | tr -dc '0-9')

  # 取前8位数字作为年月日，前缀为d
  echo "v2-${published_at:0:8}"
}

find_release_by_tag_name() {
  local repo=$1
  local target_tag_name=$2
  
  local url="https://api.github.com/repos/${repo}/releases"

  # echo "URL: $url"

  local target_release=""

  local found=false
  local page=1
  while true; do
    local curl_cmd="curl -s"
    if [[ -n "$github_token" ]]; then
      curl_cmd="$curl_cmd -H 'Authorization: Bearer $github_token'"
    fi
    local response=$(eval "$curl_cmd \"${url}?per_page=100&page=${page}\"")
    if [[ -z "$response" ]]; then
      break
    fi
    
    # 检查是否为空数组或错误信息
    local array_size=$(printf '%s' "$response" | jq 'length')
    if [[ "$array_size" == "0" ]]; then
      break
    fi
    
    # 使用临时文件来处理包含换行符的JSON响应
    local temp_file=$(mktemp)
    printf '%s' "$response" > "$temp_file"
    
    # 直接使用jq过滤匹配的tag_name
    local matched_release=$(cat "$temp_file" | jq -c --arg tag "$target_tag_name" '.[] | select(.tag_name == $tag)')
    rm -f "$temp_file"
    
    if [[ -n "$matched_release" ]]; then
      printf '%s' "$matched_release"
      found=true
      break
    fi

    page=$((page + 1))
  done
  
  if [[ "$found" == "false" ]]; then
    return 1
  fi
}

# 直接获取指定tag_name的release信息
fetch_release_info() {
  local repo="$1"
  local tag_name="$2"
  
  local temp_file=$(mktemp)
  
  # 先尝试通过tags API获取release信息
  local url="https://api.github.com/repos/${repo}/releases/tags/${tag_name}"
  
  # 对于latest标签，使用latest endpoint
  if [[ "$tag_name" == "latest" ]]; then
    url="https://api.github.com/repos/${repo}/releases/latest"
  fi
  
  local curl_cmd="curl -s"
  if [[ -n "$github_token" ]]; then
    curl_cmd="$curl_cmd -H 'Authorization: Bearer $github_token'"
  fi
  eval "$curl_cmd \"${url}\"" > "$temp_file"
  if [[ ! -s "$temp_file" ]]; then
    rm -f "$temp_file"
    echo "❌ 无法获取release信息！"
    return 1
  fi
  
  # 检查是否返回错误
  local message=$(cat "$temp_file" | jq -r '.message // empty' 2>/dev/null)
  if [[ -n "$message" ]]; then
    rm -f "$temp_file"
    echo "❌ API错误：$message"
    return 1
  fi
  
  # 压缩JSON，移除换行符和多余空格，确保输出为单行
  cat "$temp_file" | jq -c '.'
  rm -f "$temp_file"
  return 0
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

  local release=""

  # 先尝试通过fetch_release_info获取
  # echo "⏳ 正在通过API直接获取仓库 ${repo} 的标签 ${tag_name}..."
  release=$(fetch_release_info "$repo" "$tag_name")
  if [[ $? -ne 0 || -z "$release" ]]; then
    # 如果获取失败，尝试通过find_release_by_tag_name获取
    # echo "⏳ 通过API直接获取失败，尝试在所有releases中查找 ${tag_name}..."
    release=$(find_release_by_tag_name "$repo" "$tag_name")
  fi

  if [[ -z "$release" ]]; then
    echo "❌ 找不到 tag_name=${tag_name} 的release！"
    return 1
  fi

  tag_name=$(printf '%s' "$release" | jq -r '.tag_name')
  if [[ -z "$tag_name" || "$tag_name" == "null" ]]; then
    echo "❌ 找不到 tag_name！"
    return 1
  fi

  published_at=$(printf '%s' "$release" | jq -r '.published_at')
  if [[ -z "$published_at" || "$published_at" == "null" ]]; then
    echo "❌ 找不到 published_at！"
    return 1
  fi

  # TODO 如果是数字版本(220250909)则直接使用，否则根据发布时间生成版本号
  if [[ "$tag_name" =~ ^[0-9]+$ ]]; then
    release_version="$tag_name"
  else
    release_version=$(generate_app_version "$published_at")
  fi

  tar_url=$(printf '%s' "$release" | jq -r '.tarball_url')
  if [[ -z "$tar_url" || "$tar_url" == "null" ]]; then
    echo "❌ 从请求结果获取源码压缩包文件下载链接失败！"
    return 1
  fi

  zip_url=$(printf '%s' "$release" | jq -r '.zipball_url')
  if [[ -z "$zip_url" || "$zip_url" == "null" ]]; then
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

print_help() {
  # 显示帮助
  echo "用法: $0 [--context <context>] [--tag <release_tag>] [--repo <owner/repo>] [--token <github_token>] [--verbose] [--dry]"
  echo "  --context <context>   指定源码解压目录，默认为当前目录"
  echo "  --tag <release_tag>   指定要下载的版本标签；不指定时按repo自动选择，也可用 .env/环境变量MDCX_SRC_TAG"
  echo "  --repo <owner/repo>   指定源码仓库，默认'sqzw-x/mdcx'，也可用 .env/环境变量MDCX_SRC_REPO"
  echo "  --token <github_token> 指定GitHub Token以避免API速率限制，也可用环境变量GITHUB_TOKEN"
  echo "  --verbose             显示详细的下载过程"
  echo "  --dry                 只进行检查，不实际下载"
}

require_jq() {
  # 检查是否有jq命令
  if ! command -v jq > /dev/null 2>&1; then
    echo "❌ 请先安装jq命令！参考：https://command-not-found.com/jq"
    exit 1
  fi
}

load_defaults() {
  SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

  # 支持从仓库根目录 .env 读取默认值（命令行参数优先）
  if [[ -f "$SCRIPT_DIR/.env" ]]; then
    . "$SCRIPT_DIR/.env"
  fi

  release_tag="${MDCX_SRC_TAG:-}"
  default_repo="sqzw-x/mdcx"
  repo="${MDCX_SRC_REPO:-$default_repo}"
  github_token="${GITHUB_TOKEN:-}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
      --context)
        context="$2"
        shift 2
        ;;
      --tag)
        release_tag="$2"
        shift 2
        ;;
      --repo)
        repo="$2"
        shift 2
        ;;
      --token)
        github_token="$2"
        shift 2
        ;;
      --verbose)
        verbose=1
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
}

validate_inputs() {
  if [[ -n "$help" ]]; then
    print_help
    exit 0
  fi

  if [[ -z "$repo" ]]; then
    echo "❌ 未指定源码仓库"
    exit 1
  fi

  if ! printf '%s' "$repo" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'; then
    echo "❌ 源码仓库格式错误: $repo (正确格式: owner/repo)"
    exit 1
  fi

  echo "✅ 使用源码仓库: $repo"

  if [[ -z "$release_tag" ]]; then
    release_tag="$(get_default_release_tag_by_repo "$repo")"
    echo "✅ 未指定版本标签，已按仓库自动选择: $release_tag"
  else
    echo "✅ 使用指定的版本标签: $release_tag"
  fi

  if [[ -z "$context" ]]; then
    echo "❌ context is required!"
    exit 1
  fi

  if [[ ! -d "$context" ]]; then
    echo "❌ Dir $context is not exist!"
    exit 1
  fi
}

download_and_extract() {
  local file_url="$1"
  local release_version="$2"

  if [[ -z "$file_url" ]]; then
    echo "❌ 从请求结果获取下载链接失败！"
    exit 1
  fi

  if [[ -n "$dry" ]]; then
    exit 0
  fi

  echo "⏳ 下载文件..."

  local tar_path="${release_version}.tar.gz"
  local srcDir=".mdcx_src"

  if [[ -n "$verbose" ]]; then
    curl -o "$tar_path" "$file_url" -L
  else
    curl -so "$tar_path" "$file_url" -L
  fi

  if [[ $? -ne 0 ]]; then
    echo "❌ 下载文件失败！"
    exit 1
  fi

  echo "✅ 下载成功"
  echo "⏳ 开始解压..."

  # 使用tar命令解压
  rm -rf "$srcDir"
  mkdir -p "$srcDir"
  tar -zxvf "$tar_path" -C "$srcDir" --strip-components 1
  rm -f "$tar_path"
  echo "✅ 源码已解压到 $srcDir"
}

main() {
  require_jq
  load_defaults
  parse_args "$@"
  validate_inputs

  cd "$context" || exit 1

  echo "○ 将从发布仓库下载源码进行构建"

  REPO="$repo"
  TAG_NAME="${release_tag}"

  info=$(get_release_info "$REPO" "$TAG_NAME")
  if [[ $? -ne 0 ]]; then
    echo "❌ 获取仓库 ${REPO} 中 tag_name=${TAG_NAME} 的release信息失败！"
    exit 1
  else
    echo "✅ 获取仓库 ${REPO} 中 tag_name=${TAG_NAME} 的release信息成功！"
  fi
  printf '%s' "$info" | jq
  # exit 0

  # 发布时间
  published_at=$(printf '%s' "$info" | jq -r ".published_at")
  echo "📅 发布时间: $published_at"

  # 版本号
  release_version=$(printf '%s' "$info" | jq -r ".release_version")
  echo "🔢 版本号: $release_version"

  # 源码链接
  file_url=$(printf '%s' "$info" | jq -r ".tar_url")
  echo "🔗 下载链接: $file_url"

  download_and_extract "$file_url" "$release_version"

  if [ -n "$GITHUB_ACTIONS" ]; then
    echo "APP_VERSION=$release_version" >> "$GITHUB_OUTPUT"
  fi
}

main "$@"
