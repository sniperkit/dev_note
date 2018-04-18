#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

import os

from lib.meta import MetaData
from lib import prepare
from lib import terraform

META = MetaData()


class Platform:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb

    def any(self):
        tfvars_bootstrap = META.TERRAFORM_VARS.get("dcos_bootstrap")
        tfvars_master    = META.TERRAFORM_VARS.get("dcos_master")
        tfvars_agent     = META.TERRAFORM_VARS.get("dcos_agent")

        # bootstrap
        prepare.ip_detect(self.configs, self.verb)
        prepare.terraform_provision(filename=tfvars_bootstrap, configs=self.configs, verb=self.verb)

        # master
        prepare.terraform_provision(filename=tfvars_master, configs=self.configs, verb=self.verb)

        # agent
        prepare.terraform_provision(filename=tfvars_agent, configs=self.configs, verb=self.verb)

    def aws(self):
        source_module = META.TERRAFORM_EXTERNAL_MODULES.get("terraform_dcos")
        local_module  = "{}/{}".format(META.TERRAFORM_MODULE_DIR, META.TERRAFORM_LOCAL_MODULES.get("terraform_dcos"))

        if not os.path.isdir(local_module):
            terraform.get_external_module(external=source_module, destination=local_module, verb=self.verb)


def application(configs, verb):

    prepare.marathon_configs(configs=configs, verb=verb)

    prepare.trust_docker_registry(configs=configs, verb=verb)
