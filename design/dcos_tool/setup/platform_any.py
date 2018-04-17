#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from lib.meta import MetaData
from lib.prepare import create_ip_detect, create_any_provision_tfvars

META = MetaData()


class Prepare:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb

        self.bootstrap_node()
        self.master_node()
        self.agent_node()

    def bootstrap_node(self):
        create_ip_detect(self.configs, self.verb)
        create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("dcos_bootstrap"), configs=self.configs,
                                    verb=self.verb)

    def master_node(self):
        create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_master"), configs=self.configs,
                                    verb=self.verb)

    def agent_node(self):
        create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_agent"), configs=self.configs,
                                    verb=self.verb)
