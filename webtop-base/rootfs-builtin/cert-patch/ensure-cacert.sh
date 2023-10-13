#!/bin/sh

# 脚本说明：确保`cacert.pem`文件存在

# Error: Failed to perform, ErrCode: 77, 
# Reason: 'error setting certificate verify locations: CAfile: /tmp/_MEIn88rZY/curl_cffi/cacert.pem CApath: none'. 
# This may be a libcurl error, See https://curl.se/libcurl/c/libcurl-errors.html first for more details.

# https://github.com/northsea4/mdcx-docker/issues/25
# https://github.com/yifeikong/curl_cffi/blob/master/Makefile
# https://github.com/yifeikong/curl_cffi/issues/104
# https://bobcares.com/blog/curl-error-77-problem-with-the-ssl-ca-cert/
# https://curl.se/libcurl/c/libcurl-errors.html
# https://stackoverflow.com/questions/31448854/how-to-force-requests-use-the-certificates-on-my-ubuntu-system
# https://stackoverflow.com/questions/65122957/resolving-new-pip-backtracking-runtime-issue

# Action构建：
# 安装的版本：Downloading curl_cffi-0.5.9-cp37-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (7.2 MB)


# 如果不存在文件`/app/MDCx`，则不用处理
if [ ! -f "/app/MDCx" ]; then
  echo "🔧 文件/app/MDCx不存在，跳过"
  exit 0
fi

# 正常情况下，`cacert.pem`文件应该存在于`/tmp/_MEIxxxxxx/curl_cffi`目录下。
# 但是由于未知原因，有时会出现`cacert.pem`文件不存在的情况。
# 为了避免这种情况，我们将`/cert-for-mdcx/cacert.pem`文件复制到`/tmp/_MEIxxxxxx/curl_cffi`目录下。
# 注意，这个`_MEIxxxxxx`目录名是随机的，所以我们需要先找到这个目录。

# 从`/tmp`目录遍历全部`_`开头的目录，每个目录检查是否存在`curl_cffi`目录，如果存在，则将`/cert-for-mdcx/cacert.pem`复制到`curl_cffi`目录下。

ensureCacert() {
  # 遍历`/tmp`目录下的全部`_`开头的目录
  for dir in /tmp/_*; do
    # 如果目录不存在，则跳过
    if [ ! -d "$dir" ]; then
      continue
    fi

    # 如果目录下不存在`curl_cffi`目录，则跳过
    if [ ! -d "$dir/curl_cffi" ]; then
      continue
    fi

    # 如果`cacert.pem`文件不存在，则复制
    if [ ! -f "$dir/curl_cffi/cacert.pem" ]; then
      cp /cert-for-mdcx/cacert.pem $dir/curl_cffi/cacert.pem
      echo "✅ 已将/cert-for-mdcx/cacert.pem复制到$dir/curl_cffi/cacert.pem"
      return 0
    fi
  done

  # 如果没有找到`_`开头的目录，则返回错误
  echo "❌ 没有找到/tmp/_*目录"
  return 1
}

runEnsureCacert() {
  echo "========================= ensure cacert =============================="
  # 定时执行，最多执行20次，每次间隔5秒
  for i in $(seq 1 20); do
    ensureCacert
    if [ $? -eq 0 ]; then
      echo "✅ 已确保cacert.pem文件存在"
      return 0
    fi
    sleep 5
  done
}

# 异步执行
nohup runEnsureCacert > /dev/null 2>&1 &