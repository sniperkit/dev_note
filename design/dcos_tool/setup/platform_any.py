#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from lib import terraform
from lib.meta import MetaData
from lib.prepare import create_ip_detect, create_any_provision_tfvars

META = MetaData()


def prepare(configs, verb):
    # bootstrap
    create_ip_detect(configs, verb)
    create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("dcos_bootstrap"), configs=configs,
                                verb=verb)

    # master
    create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_master"), configs=configs,
                                verb=verb)

    # agent
    create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_agent"), configs=configs,
                                verb=verb)


def provision(tf_module, tf_vars, configs, verb):
    terraform.install(configs.get("terraform").get("version"), verb)

    terraform.init(module=tf_module, verb=verb)

    terraform.apply(module=tf_module, var_file="{0}/{1}".format(META.TERRAFORM_TEMPORARY_DIR, tf_vars), verb=verb)
# class Prepare:
#     def __init__(self, configs, verb):
#         self.configs = configs
#         self.verb = verb
#
#         self.bootstrap_node()
#         self.master_node()
#         self.agent_node()
#
#     def bootstrap_node(self):
#         create_ip_detect(self.configs, self.verb)
#         create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("dcos_bootstrap"), configs=self.configs,
#                                     verb=self.verb)
#
#     def master_node(self):
#         create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_master"), configs=self.configs,
#                                     verb=self.verb)
#
#     def agent_node(self):
#         create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_agent"), configs=self.configs,
#                                     verb=self.verb)
#
#
# class Provision:
#     def __init__(self, tf_module, tf_vars, configs, verb):
#         self.tf_module = tf_module
#         self.tf_vars = tf_vars
#         self.configs = configs
#         self.verb = verb
#
#     def provision(self):
#         terraform.install(self.configs.get("terraform").get("version"), self.verb)
#         terraform.init(module=self.tf_module, verb=self.verb)
#         terraform.apply(module=self.tf_module,
#                var_file="{0}/{1}".format(META.TERRAFORM_TEMPORARY_DIR, self.tf_vars),
#                verb=self.verb)
