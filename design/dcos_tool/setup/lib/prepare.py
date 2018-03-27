#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from .template import UseTemplate
from .connect import Shell
from .meta import MetaConfig


def prepare(configs):
    mconfig = MetaConfig()

    ip_detect = UseTemplate('./template/ip-detect.tpl')
    ip_detect.create_new_file(new_file='{0}/{1}'.format(mconfig.BOOTSTRAP_ROOT, mconfig.IP_DETECT),
                              data_dict={
                                  'ROUTE_DESTINATION': configs.get('bootstrap_node').get('addr')
                              })

    config_yaml = UseTemplate('./template/config.yaml.tpl')
    config_yaml.create_new_file(new_file='{0}/{1}'.format(mconfig.BOOTSTRAP_ROOT, mconfig.CONFIG_YAML),
                                data_dict={
                                    'CLUSTER_NAME': configs.get('cluster_name'),
                                    'BOOTSTRAP_HOST': configs.get('bootstrap_node').get('addr'),
                                    'BOOTSTRAP_PORT': configs.get('bootstrap_node').get('port'),
                                    'MASTER_HOSTS': '\n- '.join(configs.get('master_nodes').get('addr'))
                                })

    host_session = Shell()
    host_session.local("curl -o {0}/dcos_generate_config.sh {1}".format(mconfig.BOOTSTRAP_ROOT, configs.get('bootstrap_node').get('archive')))
