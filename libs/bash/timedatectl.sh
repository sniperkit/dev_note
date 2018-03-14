#!/usr/bin/env bash
. ./log.sh

function set_timedatectl_sync {
  sudo timedatectl set-ntp true
}