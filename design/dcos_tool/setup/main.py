#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse
import yaml

import prepare, provision, destroy

from lib.meta import MetaData
from lib.deploy import Deploy
from lib.log import LogNormal

META = MetaData()


def cli_menu_parser():
    description = 'GE tool for environment provision and application deployment'

    parser = argparse.ArgumentParser(prog='PROG', description=description)

    group_require = parser.add_argument_group('required arguments')
    group_options = parser.add_argument_group('options')

    parser.add_argument('action',
                        choices=['prepare', 'provision', 'deploy', 'destroy'],
                        help='stage action')

    parser.add_argument('--version',
                        action='version',
                        version='%(prog)s 1.0.0-alpha')

    parser.add_argument('-v',
                        dest='verb',
                        action="count",
                        default=1,
                        help = "increase verbosity level")

    group_require.add_argument('-c', '--config',
                               required=True,
                               help='give config file path')

    group_options.add_argument('-s', '--stage',
                               choices=['bootstrap', 'application'],
                               required='prepare' in os.sys.argv,
                               help='prepare stage')

    group_options.add_argument('-p', '--platform',
                               choices=['aws', 'any'],
                               required=('prepare' or 'provision' or 'destroy') in os.sys.argv,
                               help='set platform')

    group_options.add_argument('-n', '--node',
                               choices=['bootstrap', 'master', 'agent'],
                               required='provision' in os.sys.argv and
                                        'any' in os.sys.argv,
                               help='set node purpose')

    args = parser.parse_args()
    LogNormal(DEBUG={"message": str(args)}, verb=args.verb)

    return args


def set_configs(args):
    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    configs["platform"] = args.platform

    LogNormal(DEBUG={"message": str(configs)}, verb=args.verb)

    return configs


if __name__ == "__main__":

    args = cli_menu_parser()

    configs = set_configs(args)

    if args.action == 'prepare' and args.stage == 'bootstrap':
        set_platform = prepare.Platform(configs=configs, verb=args.verb)

        if configs.get("platform") == "aws":
            set_platform.aws()
        else:
            set_platform.any()

    if args.action == 'prepare' and args.stage == 'application':
        prepare.application(configs=configs, verb=args.verb)

    if args.action == 'provision':
        set_platform = provision.Platform(configs=configs, verb=args.verb)

        if args.platform == "aws":
            set_platform.aws(
                tf_module="{}/aws".format(META.TERRAFORM_LOCAL_MODULES.get("terraform_dcos")),
                tf_vars=META.TERRAFORM_VARS.get("terraform_dcos"))
        else:
            set_platform.any(
                tf_module=META.TERRAFORM_LOCAL_MODULES.get("dcos_{}".format(args.node)),
                tf_vars=META.TERRAFORM_VARS.get("dcos_{}".format(args.node))
            )

    if args.action == 'deploy':
        Deploy(configs=configs, verb=args.verb).with_marathon()

    if args.action == 'destroy':
        set_platform = destroy.Platform(configs=configs, verb=args.verb)

        if args.platform == "aws":
            set_platform.aws(
                tf_module="{}/aws".format(META.TERRAFORM_LOCAL_MODULES.get("terraform_dcos")),
                tf_vars=META.TERRAFORM_VARS.get("terraform_dcos"))
        else:
            set_platform.any()
