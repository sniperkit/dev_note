#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from os.path import abspath


class MetaData:
    TERRAFORM_TEMPLATE_DIR = abspath('./template/terraform')
    TERRAFORM_TEMPORARY_DIR = abspath('./tmp/terraform')
    TERRAFORM_RUN_DIR = '/usr/bin'
    TERRAFORM_MODULE_DIR = abspath('./terraform')
    TERRAFORM_MODULES = dict(
        dcos_bootstrap='dcos_bootstrap'
    )
    TERRAFORM_VARS = dict(
        dcos_bootstrap='bootstrap.tfvars'
    )

    BOOTSTRAP_SCRIPT = '/opt/dcos_bootstrap/dcos_generate_config.sh'
    BOOTSTRAP_TFVARS = 'bootstrap.tfvars'
    MESOS_MASTER_TFVARS = 'mesos_master_tfvars'
    MESOS_AGENT_TFVARS = 'mesos_agent_tfvars'

    DCOS_TEMPLATE_DIR = abspath('./template/dcos')
    DCOS_TEMPORARY_DIR = abspath('./tmp/dcos')

    IP_DETECT = "ip-detect"
    CONFIG_YAML = 'config.yaml'

    DOCKER_CERT_DIR = '/etc/docker/certs.d/'
    MESOS_CERT_DIR = '/var/lib/dcos_bootstrap/pki/tls/certs'

    MARATHON_TEMPLATE_DIR = abspath('./template/marathon')
    MARATHON_DEPLOY_CONFIG = 'marathon_config.json'
