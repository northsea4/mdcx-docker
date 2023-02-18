#!/bin/bash
# path=/tmp////
# while [ "${path: -1}" == "/" ]
# do
#     path=${path%/}
# done
# echo $path

path=/tmp////
path=$(echo "$path" | sed 's:/*$::')
echo $path
