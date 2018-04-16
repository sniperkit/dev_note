#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from .template import UseTemplate
from .meta import MetaData
from .connect import Shell, SshSession


class PrepareBootstrap:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb
        self.meta = MetaData()

        self.bootstrap()
        self.mesos_master()
        self.mesos_agent()

    def bootstrap(self):
        ip_detect = UseTemplate(
            template='{0}/{1}.tpl'.format(self.meta.DCOS_TEMPLATE_DIR, self.meta.IP_DETECT),
            verb=self.verb
        )
        ip_detect.create_new_file(
            new_file='{0}/{1}'.format(self.meta.DCOS_TEMPORARY_DIR, self.meta.IP_DETECT),
            data_dict={
                'ROUTE_DESTINATION': self.configs.get('bootstrap_node').get('address')
            }
        )

        bootstrap_tfvars = UseTemplate(
            template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.TERRAFORM_VARS.get('dcos_bootstrap')),
            verb=self.verb
        )

        bootstrap_tfvars.create_new_file(
            new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.TERRAFORM_VARS.get('dcos_bootstrap')),
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
            template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.TERRAFORM_VARS.get('mesos_master')),
            verb=self.verb
        )

        master_tfvars.create_new_file(
            new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.TERRAFORM_VARS.get('mesos_master')),
            data_dict={
                'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
                'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
                'MESOS_MASTER_LIST': "\", \"".join(addr for addr in self.configs.get('master_nodes').get('address')),
                'MESOS_MASTER_COUNT': len(self.configs.get('master_nodes').get('address')),
                'MESOS_MASTER_USERNAME': self.configs.get('master_nodes').get('username'),
                'MESOS_MASTER_PASSWORD': self.configs.get('master_nodes').get('password')
            }
        )

    def mesos_agent(self):
        agent_tfvars = UseTemplate(
            template="{0}/{1}.tpl".format(self.meta.TERRAFORM_TEMPLATE_DIR, self.meta.TERRAFORM_VARS.get('mesos_agent')),
            verb=self.verb
        )

        agent_tfvars.create_new_file(
            new_file="{0}/{1}".format(self.meta.TERRAFORM_TEMPORARY_DIR, self.meta.TERRAFORM_VARS.get('mesos_agent')),
            data_dict={
                'BOOTSTRAP_HOST': self.configs.get('bootstrap_node').get('address'),
                'BOOTSTRAP_WEB_PORT': self.configs.get('bootstrap_node').get('ports').get('web'),
                'MESOS_AGENT_LIST': "\", \"".join(addr for addr in self.configs.get('agent_nodes').get('address')),
                'MESOS_AGENT_COUNT': len(self.configs.get('agent_nodes').get('address')),
                'MESOS_AGENT_USERNAME': self.configs.get('agent_nodes').get('username'),
                'MESOS_AGENT_PASSWORD': self.configs.get('agent_nodes').get('password')
            }
        )


class PrepareApplication:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb
        self.meta = MetaData()

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

    def trust_registry(self):
        for host in self.configs.get('agent_nodes').get('address'):
            try:
                _session = SshSession(
                    dest_host=host,
                    dest_user=self.configs.get('agent_nodes').get('username'),
                    dest_password=self.configs.get('agent_nodes').get('password'),
                    verbosity=self.verb
                )

                agent_session = Shell(
                    verb=self.verb,
                    session=_session.login_with_password()
                )

                for registry in self.configs.get('private_registries'):
                    docker_cert_dir = "{0}/{1}:{2}".format(
                        self.meta.DOCKER_CERT_DIR,
                        registry.get('host'),
                        registry.get('port')
                    )

                    commands = dict(
                        create_docker_crt_dir="[ ! -d {0} ] && mkdir -p {0} || exit 0".format(
                            docker_cert_dir
                        ),
                        create_mesos_crt_dir="[ ! -d {0} ] && mkdir -p {0} || exit 0".format(
                            self.meta.MESOS_CERT_DIR
                        ),
                        set_docker_crt="echo '{0}' > {1}/ca.crt".format(
                            registry.get('certificate'),
                            docker_cert_dir
                        ),
                        set_mesos_crt="echo '{0}' > {1}/`echo '{0}' | openssl x509 -hash -noout`.0".format(
                            registry.get('certificate'),
                            self.meta.MESOS_CERT_DIR
                        )
                    )

                    agent_session.remote(command=commands.get("create_docker_crt_dir"),
                                         info="create dcos_bootstrap cert-directory if not exist")
                    agent_session.remote(command=commands.get("create_mesos_crt_dir"),
                                         info="create mesos cert-directory if not exist")
                    agent_session.remote(command=commands.get("set_docker_crt"),
                                         info="set docker trust registry")
                    agent_session.remote(command=commands.get("set_mesos_crt"),
                                         info="set mesos trust docker download")

            finally:
                if agent_session.session:
                    agent_session.session.close()
