#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from .connect import Shell
from .meta import MetaData

META = MetaData()


def _install(version, verb):
    archive = "https://releases.hashicorp.com/terraform/{0}/terraform_{0}_linux_amd64.zip".format(version)

    _pshell = Shell(verb)

    cmds = dict(
        get_version="terraform version",
        download_and_unzip="cd {0} && curl -O {1} | unzip -d {2}".format(
            META.TERRAFORM_TMP, archive, META.TERRAFORM_RUN),
    )

    _pshell.local(command=cmds["get_version"], info="get terraform version", ignore_err=True)
    pass


def _init():
    pass


def _apply():
    pass


class Bootstrap:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb

    def provision(self):
        _install(self.configs.get("terraform").get("version"), self.verb)