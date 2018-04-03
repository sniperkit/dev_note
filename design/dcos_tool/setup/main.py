#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse
import yaml

from lib.prepare import prepare
from lib.provision import provision_bootstrap, provision_master, provision_agent, provision_agent_registry


def cli_menu_parser():
    parser = argparse.ArgumentParser(description='Deploy Cluster')

    parser.add_argument('-a', '--action',
                        choices=['prepare', 'provision', 'deploy'],
                        help='setup action <prepare, provision, deployment>',
                        required=True)

    parser.add_argument('-n', '--node',
                        choices=['bootstrap', 'master', 'agent'],
                        help='node choice <bootstrap, master, agent>',
                        required=('-a' or '--action') and 'provision' in os.sys.argv)

    parser.add_argument('-A', '--application',
                        choices=['investigator'],
                        help='applications <investigator, ...>',
                        required=('-a' or '--action') and 'deploy' in os.sys.argv)

    parser.add_argument('-c', '--config',
                        help='config file in yaml',
                        required=True)

    return parser.parse_args()


if __name__ == "__main__":
    # require: paramiko, pyyaml, ntpd, group nogroup, mount -o remount,exec /tmp
    args = cli_menu_parser()
    print(args)

    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    if args.action == 'prepare':
        prepare(configs=configs)

    if args.action == 'provision' and args.node == 'bootstrap':
        provision_bootstrap(configs=configs)
    if args.action == 'provision' and args.node == 'master':
        provision_master(configs=configs)
    if args.action == 'provision' and args.node == 'agent':
        # provision_agent(configs=configs)
        provision_agent_registry(configs=configs)

    # if args.action == 'deploy' and args.application == 'investigator':
    #     deploy_investigator(configs=configs.get("applications").get("investigator"))
