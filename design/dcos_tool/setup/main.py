#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse
import yaml

from lib.template import UseTemplate
from lib.connect import Shell

# parser = argparse.ArgumentParser(description='Deploy Cluster')
# parser.add_argument('--config', help='config file')
# args = parser.parse_args()

# print(args.config)

# PARSE YAML
# with open(args.config) as f_stream:
#     _config=yaml.load(f_stream)
# print(_config.get('a list')[0])

# SSH CONNECT
# p_session=SshSession(dest_host="192.168.201.112", dest_password="", dest_user="root")

# SSH COMMAND
# p_shell=Shell(session=p_session.login_with_password())
# p_shell.input(input="echo 'hello'")
# print(p_shell.response_lines())

# TEMPLATE
# tpl=UseTemplate('./test.tpl')
# tpl.create_new_file(file_out='./test.out', data_dict={'key': 'value', 'foo': 'bar'})

BOOTSTRAP_ROOT = './tmp/dcos_bootstrap'
IP_DETECT = "genconf/ip-detect"
CONFIG_YAML = 'genconf/config.yaml'
BOOTSTRAP_SCRIPT = '/opt/dcos_bootstrap/dcos_generate_config.sh'


def cli_menu_parser():
    parser = argparse.ArgumentParser(description='Deploy Cluster')

    parser.add_argument('--action', choices=['prepare', 'bootstrap'], help='prepare, bootstrap (default: %(default))', )
    parser.add_argument('-c', '--config', help='config file in yaml')

    return parser.parse_args()


def prepare(configs):
    ip_detect = UseTemplate('./template/ip-detect.tpl')
    ip_detect.create_new_file(new_file='{0}/{1}'.format(BOOTSTRAP_ROOT, IP_DETECT),
                              data_dict={
                                  'ROUTE_DESTINATION': configs.get('bootstrap_node').get('addr')
                              })

    config_yaml = UseTemplate('./template/config.yaml.tpl')
    config_yaml.create_new_file(new_file='{0}/{1}'.format(BOOTSTRAP_ROOT, CONFIG_YAML),
                                data_dict={
                                    'CLUSTER_NAME': configs.get('cluster_name'),
                                    'BOOTSTRAP_HOST': configs.get('bootstrap_node').get('addr'),
                                    'BOOTSTRAP_PORT': configs.get('bootstrap_node').get('port'),
                                    'MASTER_HOSTS': '\n- '.join(configs.get('master_nodes').get('addr'))
                                })

    host_session = Shell()
    host_session.local("curl -o {0}/dcos_generate_config.sh {1}".format(BOOTSTRAP_ROOT, configs.get('bootstrap_node').get('archive')))


def bootstrap(configs):
    bootstrap_session = Shell()
    # bootstrap_session.local("curl -o {0} {1}".format(BOOTSTRAP_SCRIPT, configs.get('bootstrap_node').get('archive')))

    # bootstrap_session = Shell()

    command = "cd {0} && /bin/bash ./dcos_generate_config.sh".format(BOOTSTRAP_ROOT)
    # command = "cntr=0; while [[ $cntr -lt 10 ]]; do sleep 1; echo $cntr; cntr=$((cntr+1)); done"
    # command = "error"
    bootstrap_session.local(command)


if __name__ == "__main__":
    args = cli_menu_parser()
    print(args)

    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    # ip_detect = UseTemplate('./template/ip-detect.tpl')
    # ip_detect.create_new_file(file_out=IP_DETECT,
    #                           data_dict={
    #                               'ROUTE_DESTINATION': configs.get('bootstrap_node').get('addr')
    #                           })
    #
    # config_yaml = UseTemplate('./template/config.yaml.tpl')
    # config_yaml.create_new_file(file_out=CONFIG_YAML,
    #                             data_dict={
    #                                 'CLUSTER_NAME': configs.get('cluster_name'),
    #                                 'BOOTSTRAP_HOST': configs.get('bootstrap_node').get('addr'),
    #                                 'BOOTSTRAP_PORT': configs.get('bootstrap_node').get('port'),
    #                                 'MASTER_HOSTS': '\n- '.join(configs.get('master_nodes').get('addr'))
    #                             })

    if args.action == 'prepare':
        prepare(configs=configs)
    if args.action == 'bootstrap':
        bootstrap(configs=configs)
        # bootstrap(configs=configs)


    # p_localshell = Shell().local(command=BOOTSTRAP_SCRIPT)
    # print(Shell().local(command=BOOTSTRAP_SCRIPT))




