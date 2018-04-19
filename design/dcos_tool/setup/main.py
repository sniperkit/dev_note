#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse
import yaml

import prepare, provision

from lib.meta import MetaData
from lib.deploy import Deploy
from lib.log import LogNormal

META = MetaData()


def cli_menu_parser():
    parser = argparse.ArgumentParser(description='GE tool for environment provision and application deployment')

    parser.add_argument('-a', '--action',
                        choices=['prepare', 'provision', 'deploy'],
                        help='run action',
                        required=True)

    parser.add_argument('-p', '--prepare',
                        choices=['bootstrap', 'application'],
                        help='prepare requirements',
                        required=('-a' or '--action') and 'prepare' in os.sys.argv)

    parser.add_argument('-P', '--platform',
                        choices=['aws', 'any'],
                        help='set platform',
                        required=('-a' or '--action') and
                                 ('prepare' or 'provision') in os.sys.argv,
                        default='any')

    parser.add_argument('-n', '--node',
                        choices=['bootstrap', 'master', 'agent'],
                        help='set node purpose',
                        required=('-a' or '--action') and
                                 'provision' in os.sys.argv and
                                 'any' in os.sys.argv)

    parser.add_argument('-c', '--config',
                        help='give config file path',
                        required=True)

    parser.add_argument('-v', '--verbosity',
                        action="count",
                        help="increase output verbosity",
                        default=1)

    parser.add_argument('--version',
                        action='version',
                        version='%(prog)s 1.0.0-alpha')

    args = parser.parse_args()
    LogNormal(DEBUG={"message": str(args)}, verb=args.verbosity)

    return args


def set_configs(args):
    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    configs["platform"] = args.platform

    LogNormal(DEBUG={"message": str(configs)}, verb=args.verbosity)

    return configs


if __name__ == "__main__":

    args = cli_menu_parser()

    configs = set_configs(args)

    if args.action == 'prepare' and args.prepare == 'bootstrap':
        set_platform = prepare.Platform(configs=configs, verb=args.verbosity)

        if configs.get("platform") == "aws":
            set_platform.aws()
        else:
            set_platform.any()

    if args.action == 'prepare' and args.prepare == 'application':
        prepare.application(configs=configs, verb=args.verbosity)

    if args.action == 'provision':
        set_platform = provision.Platform(configs=configs, verb=args.verbosity)

        if args.platform == "aws":
            set_platform.aws(
                tf_module="{}/aws".format(META.TERRAFORM_LOCAL_MODULES.get("terraform_dcos")),
                tf_vars="aws_{}".format(META.TERRAFORM_VARS.get("terraform_dcos")))
        else:
            set_platform.any(
                tf_module=META.TERRAFORM_LOCAL_MODULES.get("dcos_{}".format(args.node)),
                tf_vars=META.TERRAFORM_VARS.get("dcos_{}".format(args.node))
            )

    if args.action == 'deploy':
        Deploy(configs=configs, verb=args.verbosity).with_marathon()
