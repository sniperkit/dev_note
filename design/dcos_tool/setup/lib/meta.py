#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import os


class MetaConfig:
    BOOTSTRAP_ROOT = os.path.abspath('./tmp/dcos_bootstrap')
    BOOTSTRAP_SCRIPT = '/opt/dcos_bootstrap/dcos_generate_config.sh'

    IP_DETECT = "genconf/ip-detect"
    CONFIG_YAML = 'genconf/config.yaml'