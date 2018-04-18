#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import os

from .connect import Shell
from .meta import MetaData
from .log import LogNormal, LogWarn

META = MetaData()


def do_install(version, verb):
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


def do_init(source, module, verb):

    _pshell = Shell(verb)

    _pshell.local(command="terraform init -no-color".format(source, module),
                  info="terraform init",
                  set_dir="{0}/{1}".format(META.TERRAFORM_MODULE_DIR, module))


def do_apply(module, var_file, verb):
    _pshell = Shell(verb)

    _pshell.local(command="terraform apply -no-color -auto-approve -var-file={0}".format(var_file),
                  info="terraform apply {0}".format(var_file),
                  set_dir="{0}/{1}".format(META.TERRAFORM_TEMPORARY_DIR, module))


def get_external_module(external, destination, verb):
    if os.path.isdir(destination):
        LogWarn(INFO={"message": "{} exist, ignore clone".format(os.path.basename(destination))}, verb=verb)
        return False

    _pshell = Shell(verb)

    _pshell.local(command="git clone {} {}".format(external, destination),
                  info="git clone to {}".format(destination))
