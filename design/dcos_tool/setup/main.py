#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse
import yaml

from lib.template import UseTemplate
from lib.connect import Shell, SshSession

BOOTSTRAP_ROOT = os.path.abspath('./tmp/dcos_bootstrap')
IP_DETECT = "genconf/ip-detect"
CONFIG_YAML = 'genconf/config.yaml'
BOOTSTRAP_SCRIPT = '/opt/dcos_bootstrap/dcos_generate_config.sh'


def cli_menu_parser():
    parser = argparse.ArgumentParser(description='Deploy Cluster')

    parser.add_argument('-a', '--action',
                        choices=['prepare', 'bootstrap', 'deploy_master', 'deploy_agent'],
                        help='prepare, bootstrap, deploy_master, deploy_agent',
                        required=True)
    parser.add_argument('-c', '--config',
                        help='config file in yaml',
                        required=True)

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

    command = "cd {0} && /bin/bash ./dcos_generate_config.sh".format(BOOTSTRAP_ROOT)
    bootstrap_session.local(command)

    command = "docker run -d -p {0}:80 -v {1}/genconf/serve:/usr/share/nginx/html:ro nginx".format(
        configs.get('bootstrap_node').get('port'),
        BOOTSTRAP_ROOT
    )
    bootstrap_session.local(command)


def deploy_master(configs):
    for host in configs.get('master_nodes').get('addr'):
        try:
            _session = SshSession(
                dest_host=host,
                dest_user=configs.get('master_nodes').get('username'),
                dest_password=configs.get('master_nodes').get('password'))

            master_session = Shell(session=_session.login_with_password())

            command = "curl -o /tmp/dcos_install.sh http://{0}:{1}/dcos_install.sh".format(
                configs.get('bootstrap_node').get('addr'),
                configs.get('bootstrap_node').get('port'))
            master_session.remote(command=command)

            if configs.get('bootstrap_node').get('addr') == host:
                sed_find = "^systemctl restart docker"
                sed_replace = "docker run -d -p {0}:80 -v {1}/genconf/serve:/usr/share/nginx/html:ro nginx".format(
                    configs.get('bootstrap_node').get('port'), BOOTSTRAP_ROOT)
                command = "sed -E -i 's#{0}#& \\n{1}#' /tmp/dcos_install.sh".format(sed_find, sed_replace)
                master_session.local(command)

            command = "/bin/bash /tmp/dcos_install.sh master"
            master_session.remote(command=command)

        finally:
            if master_session.session:
                master_session.session.close()


def deploy_agent(configs):
    for host in configs.get('agent_nodes').get('addr'):
        try:
            _session = SshSession(
                dest_host=host,
                dest_user=configs.get('agent_nodes').get('username'),
                dest_password=configs.get('agent_nodes').get('password'))

            agent_session = Shell(session=_session.login_with_password())

            command = "curl -o /tmp/dcos_install.sh http://{0}:{1}/dcos_install.sh".format(
                configs.get('bootstrap_node').get('addr'),
                configs.get('bootstrap_node').get('port'))
            agent_session.remote(command=command)

            command = "sudo /bin/bash /tmp/dcos_install.sh slave"
            agent_session.remote(command=command)

        finally:
            if agent_session.session:
                agent_session.session.close()


if __name__ == "__main__":
    # require: paramiko, pyyaml, ntpd, group nogroup, mount -o remount,exec /tmp
    args = cli_menu_parser()
    print(args)

    with open(args.config) as f_stream:
        configs=yaml.load(f_stream)

    if args.action == 'prepare':
        prepare(configs=configs)
    if args.action == 'bootstrap':
        bootstrap(configs=configs)
    if args.action == 'deploy_master':
        deploy_master(configs=configs)
    if args.action == 'deploy_agent':
        deploy_agent(configs=configs)





