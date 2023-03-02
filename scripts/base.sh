#!/bin/bash


# 从 ISO 8601 格式的时间字符串中提取时间戳
isoTimeToInt() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" "+%s")
  else
    echo $(date -d "$1" +%s)
  fi
}

# 比较前后两个版本号，等于返回0，大于返回1，小于返回-1
compareVersion () {
  if [[ $1 == $2 ]]
  then
    echo 0
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
      echo 1
      return 1
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]}))
    then
      echo -1
      return -1
    fi
  done
  
  echo 0
  return 0
}