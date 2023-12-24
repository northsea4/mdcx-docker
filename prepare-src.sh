#!/bin/sh

# 脚本说明：下载应用源码并解压到指定的目录(通过`context`指定)下的`.mdcx_src`目录
# 一般只用于构建镜像流程，普通用户可以忽略。
# UPDATE 2023-12-24 17:08:03 使用新的源码仓库:https://github.com/sqzw-x/mdcx

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

_url="https://api.github.com/repos/sqzw-x/mdcx/releases/latest"
_content=$(curl -s "$_url")

# TODO github workflow里竟然会有比较大的概率获取失败
if [[ -z "$_content" ]]; then
  echo "❌ 请求 $_url 失败！"
  exit 1
fi

# tag名称，作为版本号
tagName=$(printf '%s' $_content | jq -r ".tag_name")
archiveVersion=$(echo $tagName | sed 's/v//g')

# 源码压缩包(tar格式)链接
archiveUrl=$(printf '%s' $_content | jq -r ".tarball_url")

if [[ -z "$archiveUrl" ]]; then
  echo "❌ 从请求结果获取源码压缩包文件下载链接失败！"
  echo "🔘 请求链接：$_url"
  echo "🔘 请求结果：$_content"
  exit 1
fi

if [[ -n "$verbose" ]]; then
  echo "ℹ️ TAG名称: $tagName"
  echo "🔗 下载链接: $archiveUrl"
fi
echo "ℹ️ 已发布版本: $archiveVersion"

if [[ -z "$archiveUrl" ]]; then
  echo "❌ 从请求结果获取下载链接失败！"
  exit 1
fi

echo "⏳ 下载文件..."

archivePath="$archiveVersion.tar.gz"
srcDir=".mdcx_src"

if [[ -n "$verbose" ]]; then
  curl -o $archivePath $archiveUrl -L
else
  curl -so $archivePath $archiveUrl -L
fi

echo "✅ 下载成功"
echo "⏳ 开始解压..."

# 使用tar命令解压
rm -rf $srcDir
mkdir -p $srcDir
tar -zxvf $archivePath -C $srcDir --strip-components 1
rm -f $archivePath
echo "✅ 源码已解压到 $srcDir"

if [ -n "$GITHUB_ACTIONS" ]; then
  echo "APP_VERSION=$archiveVersion" >> $GITHUB_OUTPUT
fi
