#!/usr/bin/env bash
export LANG=C.UTF-8

release="$(uname -r)"

result=`ip route get $ROUTE_DESTINATION`

[[ $release = *"coreos"* ]] && echo ${result} | awk '{print $5; exit}' && exit 0

if [[ `echo $result | awk '{print $1; exit}'` == local ]]; then
  echo ${result} | awk '{print $6; exit}' && exit 0
else
  echo ${result} | awk '{print $5; exit}' && exit 0
fi

