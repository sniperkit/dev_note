#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse
import yaml

from lib.prepare import PrepareBootstrap, PrepareApplication
from lib.provision import BootstrapNode, MasterNode, AgentNode
from lib.deploy import Deploy


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

    # require:
    # curl https://bootstrap.pypa.io/get-pip.py | python36
    # paramiko, pyyaml, ntpd, groupadd nogroup, mount -o remount,exec /tmp

    args = cli_menu_parser()
    print(args)

    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    if args.action == 'prepare' and args.prepare == 'bootstrap':
        PrepareBootstrap(configs=configs, verbosity=args.verbosity)
    if args.action == 'prepare' and args.prepare == 'application':
        PrepareApplication(configs=configs, verbosity=args.verbosity)

    if args.action == 'provision' and args.node == 'bootstrap':
        BootstrapNode(configs=configs, verbosity=args.verbosity)
    if args.action == 'provision' and args.node == 'master':
        MasterNode(configs=configs, verbosity=args.verbosity)
    if args.action == 'provision' and args.node == 'agent':
        AgentNode(configs=configs, verbosity=args.verbosity).bootstrap()
        AgentNode(configs=configs, verbosity=args.verbosity).trust_registry()

    if args.action == 'deploy':
        Deploy(configs=configs, verbosity=args.verbosity).with_marathon()

    # if args.action == 'deploy' and args.application == 'investigator':
    #     deploy_investigator(configs=configs.get("applications").get("investigator"))
