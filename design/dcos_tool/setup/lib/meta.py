#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from os.path import abspath


class MetaData:
    BOOTSTRAP_ROOT = abspath('./tmp/dcos_bootstrap')
    BOOTSTRAP_SCRIPT = '/opt/dcos_bootstrap/dcos_generate_config.sh'

    IP_DETECT = "genconf/ip-detect"
    CONFIG_YAML = 'genconf/config.yaml'

    MARATHON_ROOT = abspath('./template/marathon')
