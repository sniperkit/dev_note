#!/usr/bin/env bash
export LANG=C.UTF-8

release="$(uname -r)"

[[ $release = *"coreos"* ]] && ip route get $ROUTE_DESTINATION | awk '{print $5; exit}' && exit 0

ip route get $ROUTE_DESTINATION | awk '{print $6; exit}' && exit 0
