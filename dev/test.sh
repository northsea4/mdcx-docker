#!/bin/bash

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -p|--path)
      path="$2"
      shift # past argument
      shift # past value
      ;;
    --dry)
      dry_run=1
      shift # past argument
      ;;
    -h|--help)
      help=1
      shift # past argument
      ;;
    *)    # unknown option
      path="$1"
      break
      ;;
  esac
done

if [ -z $help ] && [ -z $path ]; then
  help=1
fi

if [ -n "$help" ]; then
  echo "脚本功能：自动判断所提供路径对应的系统挂载点，并设置挂载点为共享挂载。"
  echo ""
  echo "示例1：./make-shared.sh /volume2/clouddrive2/data"
  echo "示例2：./make-shared.sh --path /volume2/clouddrive2/data"
  echo "示例3：./make-shared.sh --path /volume2/clouddrive2/data --dry"
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

if [ -n "$dry_run" ]; then
  echo "DRY RUN: The path is $path"
else
  echo "The path is $path"
  # Perform actual processing
fi