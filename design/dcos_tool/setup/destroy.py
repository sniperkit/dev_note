#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from lib import terraform
from lib.meta import MetaData

META = MetaData()


class Platform():
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb

    def any(self):
        raise NotImplementedError("Not implemented")

    def aws(self, tf_module, tf_vars):
        terraform_vars = "{0}/{1}".format(META.TERRAFORM_TEMPORARY_DIR, tf_vars)

        terraform.do_destroy(module=tf_module, var_file=terraform_vars, verb=self.verb)
