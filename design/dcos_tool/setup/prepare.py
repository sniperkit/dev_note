#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from lib.meta import MetaData
from lib import prepare

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


def application(configs, verb):

    prepare.marathon_configs(configs=configs, verb=verb)

    prepare.trust_docker_registry(configs=configs, verb=verb)
