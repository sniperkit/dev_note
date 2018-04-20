#!/usr/bin/env bash

function install_pip() {
  curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
  python get-pip.py
}
