#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from os.path import abspath


class MetaData:
    BOOTSTRAP_ROOT = abspath('./tmp/dcos_bootstrap')
    BOOTSTRAP_SCRIPT = '/opt/dcos_bootstrap/dcos_generate_config.sh'

    IP_DETECT = "genconf/ip-detect"
    CONFIG_YAML = 'genconf/config.yaml'

    DOCKER_CERT_DIR = '/etc/docker/certs.d/'
    MESOS_CERT_DIR = '/var/lib/dcos/pki/tls/certs'

    MARATHON_TEMPLATE_DIR = abspath('./template/marathon')
    MARATHON_DEPLOY_CONFIG = 'marathon_config.json'
