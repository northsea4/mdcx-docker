#!/bin/bash

fileSystemList=()
mountPointList=()

while read line; do
  fileSystem=$(echo $line | awk '{print $1}')
  mountPoint=$(echo $line | awk '{print $6}')
  
  if [[ $fileSystem != *"CloudFS"* ]] && [[ $fileSystem != *"rclone"* ]]; then
    fileSystemList=( "${fileSystemList[@]}" "$fileSystem" )
    mountPointList=( "${mountPointList[@]}" "$mountPoint" )
  fi
done < <(df -h | tail -n +2)

for ((i=0;i<${#fileSystemList[@]};i++)); do
  echo "${fileSystemList[i]} ${mountPointList[i]}"
done
