#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from .template import UseTemplate
from .meta import MetaData


class PrepareBootstrap:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb
        self.meta = MetaData()

        self.bootstrap()

    def bootstrap(self):
        ip_detect = UseTemplate(
            template='{0}/{1}.tpl'.format(self.meta.DCOS_TEMPLATE_DIR, self.meta.IP_DETECT),
            verb=self.verb
        )
        ip_detect.create_new_file(
            new_file='{0}/{1}'.format(self.meta.DCOS_TEMPORARY_DIR, self.meta.IP_DETECT),
            data_dict={
                'ROUTE_DESTINATION': self.configs.get('bootstrap_node').get('addr')
            }
        )

        bootstrap_tfvars = UseTemplate(
            template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.BOOTSTRAP_TFVARS),
            verb=self.verb
        )

        bootstrap_tfvars.create_new_file(
            new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.BOOTSTRAP_TFVARS),
            data_dict={
                'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
                'BOOTSTRAP_SSH_PORT': self.configs.get('bootstrap_node').get('ports').get('ssh'),
                'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
                'BOOTSTRAP_USERNAME': self.configs.get('bootstrap_node').get('username'),
                'BOOTSTRAP_PASSWORD': self.configs.get('bootstrap_node').get('password'),
                'MESOS_MASTER_LIST': "\", \"".join(addr for addr in self.configs.get('master_nodes').get('address')),
                'DCOS_CLUSTER_NAME': self.configs.get('cluster_name'),
                'DCOS_DOWNLOAD_PATH': self.configs.get('dcos_archive'),
                'DCOS_IP_DETECT_SCRIPT': "{0}/{1}".format(self.meta.DCOS_TEMPORARY_DIR, self.meta.IP_DETECT)
            }
        )

    def mesos_master(self):
        master_tfvars = UseTemplate(
            template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.MESOS_MASTER_TFVARS),
            verb=self.verb
        )

        master_tfvars.create_new_file(
            new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.MESOS_MASTER_TFVARS),
            data_dict={
                'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
                'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
                'MESOS_MASTER_LIST': "\", \"".join(addr for addr in self.configs.get('master_nodes').get('address')),
                'MESOS_MASTER_COUNT': len(self.configs.get('master_nodes').get('address'))
            }
        )

    def mesos_agent(self):
        agent_tfvars = UseTemplate(
            template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.MESOS_AGENT_TFVARS),
            verb=self.verb
        )

        agent_tfvars.create_new_file(
            new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.MESOS_AGENT_TFVARS),
            data_dict={
                'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
                'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
                'MESOS_AGENT_LIST': "\", \"".join(addr for addr in self.configs.get('agent_nodes').get('address')),
                'MESOS_AGENT_COUNT': len(self.configs.get('agent_nodes').get('address'))
            }
        )


class PrepareApplication:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb
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
                verb=self.verb
            )

            _call_tpl.create_new_file(new_file=_config, data_dict=_data_dict)
