#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from .template import UseTemplate
from .connect import Shell
from .meta import MetaData


class PrepareBootstrap:
    def __init__(self, configs, verbosity):
        self.configs = configs
        self.verbosity = verbosity
        self.meta = MetaData()

        self.bootstrap()

    def bootstrap(self):
        ip_detect = UseTemplate('./template/ip-detect.tpl', verbosity=self.verbosity)
        ip_detect.create_new_file(new_file='{0}/{1}'.format(self.meta.BOOTSTRAP_ROOT, self.meta.IP_DETECT),
                                  data_dict={
                                      'ROUTE_DESTINATION': self.configs.get('bootstrap_node').get('addr')
                                  })

        config_yaml = UseTemplate('./template/config.yaml.tpl', verbosity=self.verbosity)
        config_yaml.create_new_file(new_file='{0}/{1}'.format(self.meta.BOOTSTRAP_ROOT, self.meta.CONFIG_YAML),
                                    data_dict={
                                        'CLUSTER_NAME': self.configs.get('cluster_name'),
                                        'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('addr'),
                                        'BOOTSTRAP_PORT': self.configs.get('bootstrap_node').get('port'),
                                        'MASTER_HOSTS': '\n- '.join(self.configs.get('master_nodes').get('addr'))
                                    })

        _cmd = "curl -o {0}/dcos_generate_config.sh {1}".format(
            self.meta.BOOTSTRAP_ROOT, self.configs.get('bootstrap_node').get('archive'))
        host_session = Shell(verbosity=self.verbosity)
        host_session.local(command=_cmd, info="download bootstrap binary")


class PrepareApplication:
    def __init__(self, configs, verbosity):
        self.configs = configs
        self.verbosity = verbosity
        self.meta = MetaData()

        self.application()

    def application(self):
        for application in self.configs.get("applications"):

            _data_dict = {}
            for key in application:
                _data_dict.update({key.upper(): '{0}'.format(application.get(key))})

            _config = "{0}/{1}/{2}/marathon_config.json".format(
                self.meta.MARATHON_TEMPLATE_DIR,
                application.get("name"),
                application.get("version")
            )

            _call_tpl = UseTemplate(
                template=_config + '.tpl',
                verbosity=self.verbosity
            )

            _call_tpl.create_new_file(new_file=_config,
                                      data_dict=_data_dict)
