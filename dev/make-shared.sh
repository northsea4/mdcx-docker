#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "❌ 请以root用户执行！"
  exit
fi

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -p|--path)
      path="$2"
      shift
      shift
      ;;
    --dry)
      dry_run=1
      shift
      ;;
    -h|--help)
      help=1
      shift
      ;;
    *)
      path="$1"
      shift
      ;;
  esac
done

if [ -z $help ] && [ -z $path ]; then
  help=1
fi

if [ -n "$help" ]; then
  echo "脚本功能：自动判断所提供路径对应的系统挂载点，并设置挂载点为共享挂载。"
  echo ""
  echo "示例1：sudo ./make-shared.sh /volume2/clouddrive2/data"
  echo "示例2：sudo ./make-shared.sh --path /volume2/clouddrive2/data"
  echo "示例3：sudo ./make-shared.sh --path /volume2/clouddrive2/data --dry"
  echo ""
  echo "参数说明："
  echo "--path, -p   路径，即映射关系的宿主机里的路径"
  echo "--dry        只显示过程信息，不实际执行具体的处理"
  echo "--help, -h   显示帮助信息"
  echo ""
  echo "作者：生瓜太保"
  echo "版本：20230202"
  exit 0
fi

if [ -z "$path" ]; then
  echo "❌ 请指定路径！"
  echo "⭕️ 示例：sudo ./make-shared.sh --path /volume2/clouddrive2/data"
  exit
else
  echo "⭕️ 提供的路径：$path"
fi

mountPointList=()

while read line; do
  fileSystem=$(echo $line | awk '{print $1}')
  mountPoint=$(echo $line | awk '{print $6}')
  
  if [[ $fileSystem != *"CloudFS"* ]]; then
    mountPointList=( "${mountPointList[@]}" "$mountPoint" )
  fi
done < <(df -h | tail -n +2)

# echo ${mountPointList[@]}

targetMountPoint=""

formerPath=$path

while true; do
  formerPath=$(dirname $formerPath)

  for i in ${!mountPointList[@]}; do
    mp=${mountPointList[$i]}
    if [[ $formerPath == "$mp" ]]; then
      targetMountPoint=$mp
      break 2
    fi
  done

  if [[ $formerPath == "/" ]]; then
    break
  fi
done

if [[ -z "$targetMountPoint" ]]; then
  echo "❌ 判断挂载点失败"
  exit 1
fi

echo "✅ 指定目录对应的系统挂载点是 $targetMountPoint"

if [ -n "$dry_run" ]; then
  echo "⭕️ 设置该挂载点为共享挂载，请执行以下命令："
  echo "sudo mount --make-shared $targetMountPoint"
else
  echo "✅ 执行: sudo mount --make-shared $targetMountPoint"

  mount --make-shared $targetMountPoint
fi