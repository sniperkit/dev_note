#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

import os

from lib import terraform
from lib.meta import MetaData

META = MetaData()


class Platform():
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb

    def any(self, tf_module, tf_vars):
        terraform_version = self.configs.get("terraform").get("version")
        terraform_vars    = "{0}/{1}".format(META.TERRAFORM_TEMPORARY_DIR, tf_vars)

        terraform.do_install(version=terraform_version, verb=self.verb)

        terraform.do_init(source=META.TERRAFORM_MODULE_DIR, module=tf_module, verb=self.verb)

        terraform.do_apply(module=tf_module, var_file=terraform_vars, verb=self.verb)

    def aws(self):
        print("TODO: aws provision")
