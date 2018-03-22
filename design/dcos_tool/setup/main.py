#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

import argparse
import yaml

from .lib.template import UseTemplate
from .lib.connect import Shell


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

IP_DETECT = "/opt/dcos_bootstrap/genconf/ip-detect"
CONFIG_YAML = '/opt/dcos_bootstrap/genconf/config.yaml'
BOOTSTRAP_SCRIPT = '/opt/dcos_bootstrap/dcos_generate_config.sh'


def cli_menu_parser():
    parser = argparse.ArgumentParser(description='Deploy Cluster')
    parser.add_argument('--config', help='config file in yaml')

    return parser.parse_args()


if __name__ == "__main__":
    args = cli_menu_parser()

    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    ip_detect = UseTemplate('../template/ip-detect.tpl')
    ip_detect.create_new_file(file_out=IP_DETECT,
                              data_dict={
                                  'ROUTE_DESTINATION': configs.get('bootstrap_node').get('addr')
                              })

    config_yaml = UseTemplate('../template/config.yaml.tpl')
    config_yaml.create_new_file(file_out=CONFIG_YAML,
                                data_dict={
                                    'CLUSTER_NAME': configs.get('cluster_name'),
                                    'BOOTSTRAP_HOST': configs.get('bootstrap_node').get('addr'),
                                    'BOOTSTRAP_PORT': configs.get('bootstrap_node').get('port'),
                                    'MASTER_HOSTS': '\n- '.join(configs.get('master_nodes').get('addr'))
                                })

    p_localshell = Shell().local(command=BOOTSTRAP_SCRIPT)
    print(Shell().local(command=BOOTSTRAP_SCRIPT))



