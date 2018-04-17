#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from .connect import Shell, SshSession
from ..lib.meta import MetaData
from ..lib.prepare import create_ip_detect, create_any_provision_tfvars

META = MetaData()


class Prepare:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb

    def bootstrap_node(self):
        create_ip_detect(self.configs, self.verb)
        create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("dcos_bootstrap"), configs=self.configs,
                                    verb=self.verb)

    def master_node(self):
        create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_master"), configs=self.configs,
                                    verb=self.verb)

    def agent_node(self):
        create_any_provision_tfvars(filename=META.TERRAFORM_VARS.get("mesos_agent"), configs=self.configs,
                                    verb=self.verb)

# class PrepareBootstrap:
#     def __init__(self, configs, verb):
#         self.configs = configs
#         self.verb = verb
#         self.meta = MetaData()
#
#         self.bootstrap()
#         self.mesos_master()
#         self.mesos_agent()
#
#     def bootstrap(self):
        # ip_detect = UseTemplate(
        #     template='{0}/{1}.tpl'.format(self.meta.DCOS_TEMPLATE_DIR, self.meta.IP_DETECT),
        #     verb=self.verb
        # )
        # ip_detect.create_new_file(
        #     new_file='{0}/{1}'.format(self.meta.DCOS_TEMPORARY_DIR, self.meta.IP_DETECT),
        #     data_dict={
        #         'ROUTE_DESTINATION': self.configs.get('bootstrap_node').get('address')
        #     }
        # )

        # bootstrap_tfvars = UseTemplate(
        #     template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.TERRAFORM_VARS.get('dcos_bootstrap')),
        #     verb=self.verb
        # )
        #
        # bootstrap_tfvars.create_new_file(
        #     new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.TERRAFORM_VARS.get('dcos_bootstrap')),
        #     data_dict={
        #         'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
        #         'BOOTSTRAP_SSH_PORT': self.configs.get('bootstrap_node').get('ports').get('ssh'),
        #         'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
        #         'BOOTSTRAP_USERNAME': self.configs.get('bootstrap_node').get('username'),
        #         'BOOTSTRAP_PASSWORD': self.configs.get('bootstrap_node').get('password'),
        #         'MESOS_MASTER_LIST': "\", \"".join(addr for addr in self.configs.get('master_nodes').get('address')),
        #         'DCOS_CLUSTER_NAME': self.configs.get('cluster_name'),
        #         'DCOS_DOWNLOAD_PATH': self.configs.get('dcos_archive'),
        #         'DCOS_IP_DETECT_SCRIPT': "{0}/{1}".format(self.meta.DCOS_TEMPORARY_DIR, self.meta.IP_DETECT)
        #     }
        # )

    # def mesos_master(self):
    #     master_tfvars = UseTemplate(
    #         template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.TERRAFORM_VARS.get('mesos_master')),
    #         verb=self.verb
    #     )
    #
    #     master_tfvars.create_new_file(
    #         new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.TERRAFORM_VARS.get('mesos_master')),
    #         data_dict={
    #             'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
    #             'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
    #             'MESOS_MASTER_LIST': "\", \"".join(addr for addr in self.configs.get('master_nodes').get('address')),
    #             'MESOS_MASTER_COUNT': len(self.configs.get('master_nodes').get('address')),
    #             'MESOS_MASTER_USERNAME': self.configs.get('master_nodes').get('username'),
    #             'MESOS_MASTER_PASSWORD': self.configs.get('master_nodes').get('password')
    #         }
    #     )

    # def mesos_agent(self):
    #     agent_tfvars = UseTemplate(
    #         template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.TERRAFORM_VARS.get('mesos_agent')),
    #         verb=self.verb
    #     )
    #
    #     agent_tfvars.create_new_file(
    #         new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.TERRAFORM_VARS.get('mesos_agent')),
    #         data_dict={
    #             'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
    #             'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
    #             'MESOS_AGENT_LIST': "\", \"".join(addr for addr in self.configs.get('agent_nodes').get('address')),
    #             'MESOS_AGENT_COUNT': len(self.configs.get('agent_nodes').get('address')),
    #             'MESOS_AGENT_USERNAME': self.configs.get('agent_nodes').get('username'),
    #             'MESOS_AGENT_PASSWORD': self.configs.get('agent_nodes').get('password')
    #         }
    #     )