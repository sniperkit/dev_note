#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from os.path import abspath, expanduser


class MetaData:
    TERRAFORM_TEMPLATE_DIR = abspath("./template/terraform")
    TERRAFORM_TEMPORARY_DIR = abspath("./tmp/terraform")
    TERRAFORM_RUN_DIR = "/usr/bin"
    TERRAFORM_MODULE_DIR = abspath("./terraform")
    TERRAFORM_LOCAL_MODULES = dict(
        dcos_bootstrap="dcos_bootstrap",
        dcos_master="mesos_master",
        dcos_agent="mesos_agent",
        terraform_dcos="terraform_dcos"
    )
    TERRAFORM_EXTERNAL_MODULES = dict(
        terraform_dcos="https://github.com/dcos/terraform-dcos"
    )
    TERRAFORM_VARS = dict(
        dcos_bootstrap="bootstrap.tfvars",
        dcos_master="mesos_master.tfvars",
        dcos_agent="mesos_agent.tfvars",
        terraform_dcos="terraform_dcos.tfvars"
    )

    BOOTSTRAP_SCRIPT = "/opt/dcos_bootstrap/dcos_generate_config.sh"

    DCOS_TEMPLATE_DIR = abspath("./template/dcos")
    DCOS_TEMPORARY_DIR = abspath("./tmp/dcos")

    IP_DETECT = "ip-detect"
    CONFIG_YAML = "config.yaml"

    DOCKER_CERT_DIR = "/etc/docker/certs.d/"

    MESOS_CERT_DIR = "/var/lib/dcos_bootstrap/pki/tls/certs"

    AWS_TEMPLATE_DIR = abspath("./template/aws")
    AWS_ACCESS_KEY_FILEPATH = "{}/.aws/credentials".format(expanduser("~"))

    MARATHON_TEMPLATE_DIR = abspath("./template/marathon")
    MARATHON_DEPLOY_CONFIG = "marathon_config.json"
