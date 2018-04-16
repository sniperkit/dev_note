#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import os

from .connect import Shell
from .meta import MetaData
from .log import LogNormal

META = MetaData()


def _install(version, verb):
    fzip = "terraform_{0}_linux_amd64.zip".format(version)
    archive = "https://releases.hashicorp.com/terraform/{0}/{1}".format(version, fzip)

    _pshell = Shell(verb)

    cmds = dict(
        get_version="terraform version",
        download_archive="curl {0} -o {1}/{2}".format(archive, META.TERRAFORM_TEMPORARY_DIR, fzip),
        unzip_archive="unzip {0}/{1} -d {2}".format(META.TERRAFORM_TEMPORARY_DIR, fzip, META.TERRAFORM_RUN_DIR)
    )

    ret_code = _pshell.local(command=cmds["get_version"], info="check if terraform exist", warn=True)
    if ret_code == 0:
        LogNormal(verb=verb, INFO={"message": "local terraform installed"})
    else:
        _pshell.local(command=cmds["download_archive"], info="download terraform archive")
        _pshell.local(command=cmds["unzip_archive"], info="unzip terraform archive")


def _init(module, verb):
    _pshell = Shell(verb)

    _pshell.local(command="terraform init -no-color", info="terraform init",
                  set_dir="{0}/{1}".format(META.TERRAFORM_MODULE_DIR, module))


def _apply(module, var_file, verb):
    _pshell = Shell(verb)

    _pshell.local(command="terraform apply -no-color -auto-approve -var-file={0}".format(var_file),
                  info="terraform apply {0}".format(var_file),
                  set_dir="{0}/{1}".format(META.TERRAFORM_MODULE_DIR, module))


class Bootstrap:
    def __init__(self, tf_module, tf_vars, configs, verb):
        self.tf_module = tf_module
        self.tf_vars = tf_vars
        self.configs = configs
        self.verb = verb

    def provision(self):
        _install(self.configs.get("terraform").get("version"), self.verb)
        _init(module=self.tf_module, verb=self.verb)
        _apply(module=self.tf_module,
               var_file="{0}/{1}".format(META.TERRAFORM_TEMPORARY_DIR, self.tf_vars),
               verb=self.verb)