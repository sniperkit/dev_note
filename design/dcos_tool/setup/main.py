#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse
import yaml

import prepare, provision

from lib.meta import MetaData
from lib.deploy import Deploy

META = MetaData()


def cli_menu_parser():
    parser = argparse.ArgumentParser(description='Deploy Cluster')

    parser.add_argument('-a', '--action',
                        choices=['prepare', 'provision', 'deploy'],
                        help='setup action <prepare, provision, deployment>',
                        required=True)

    parser.add_argument('-p', '--prepare',
                        choices=['bootstrap', 'application'],
                        help='prepare configs <boostrap, application>',
                        required=('-a' or '--action') and 'prepare' in os.sys.argv)

    parser.add_argument('-n', '--node',
                        choices=['bootstrap', 'master', 'agent'],
                        help='node choice <bootstrap, master, agent>',
                        required=('-a' or '--action') and 'provision' in os.sys.argv)

    parser.add_argument('-c', '--config',
                        help='config file in yaml',
                        required=True)

    parser.add_argument("-v", "--verbosity",
                        action="count",
                        help="increase output verbosity",
                        default=1)

    return parser.parse_args()


if __name__ == "__main__":

    args = cli_menu_parser()
    print(args)

    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    if args.action == 'prepare' and args.prepare == 'bootstrap':
        prepare.Platform(configs=configs, verb=args.verbosity).any()

    if args.action == 'prepare' and args.prepare == 'application':
        prepare.application(configs=configs, verb=args.verbosity)

    if args.action == 'provision':

        set_platform = provision.Platform(configs=configs, verb=args.verbosity)

        if args.node in ["bootstrap", "master", "agent"]:
            set_platform.any(
                tf_module=META.TERRAFORM_MODULES.get("dcos_{}".format(args.node)),
                tf_vars=META.TERRAFORM_VARS.get("dcos_{}".format(args.node))
            )

    if args.action == 'deploy':
        Deploy(configs=configs, verb=args.verbosity).with_marathon()
