#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from .template import UseTemplate
from .meta import MetaData
from .connect import Shell, SshSession

META = MetaData()


def create_ip_detect(configs, verb):
    _ip_detect = UseTemplate(
        template='{0}/{1}.tpl'.format(META.DCOS_TEMPLATE_DIR, META.IP_DETECT),
        verb=verb
    )
    _ip_detect.create_new_file(
        new_file='{0}/{1}'.format(META.DCOS_TEMPORARY_DIR, META.IP_DETECT),
        data_dict={
            'ROUTE_DESTINATION': configs.get('bootstrap_node').get('address')
        }
    )


def create_any_provision_tfvars(filename, configs, verb):
    UseTemplate(
        template="{0}/any_{1}.tpl".format(META.TERRAFORM_TEMPLATE_DIR, filename),
        verb=verb
    ).create_new_file(
        new_file="{0}/{1}".format(META.TERRAFORM_TEMPORARY_DIR, filename),
        data_dict={
            'DCOS_CLUSTER_NAME': configs.get('cluster_name'),
            'DCOS_DOWNLOAD_PATH': configs.get('dcos_archive'),
            'DCOS_IP_DETECT_SCRIPT': "{0}/{1}".format(META.DCOS_TEMPORARY_DIR, META.IP_DETECT),
            'BOOTSTRAP_HOST': configs.get('bootstrap_node').get('address'),
            'BOOTSTRAP_SSH_PORT': configs.get('bootstrap_node').get('ports').get('ssh'),
            'BOOTSTRAP_WEB_PORT': configs.get('bootstrap_node').get('ports').get('web'),
            'BOOTSTRAP_USERNAME': configs.get('bootstrap_node').get('username'),
            'BOOTSTRAP_PASSWORD': configs.get('bootstrap_node').get('password'),
            'MESOS_MASTER_LIST': "\", \"".join(addr for addr in configs.get('master_nodes').get('address')),
            'MESOS_MASTER_COUNT': len(configs.get('master_nodes').get('address')),
            'MESOS_MASTER_USERNAME': configs.get('master_nodes').get('username'),
            'MESOS_MASTER_PASSWORD': configs.get('master_nodes').get('password'),
            'MESOS_AGENT_LIST': "\", \"".join(addr for addr in configs.get('agent_nodes').get('address')),
            'MESOS_AGENT_COUNT': len(configs.get('agent_nodes').get('address')),
            'MESOS_AGENT_USERNAME': configs.get('agent_nodes').get('username'),
            'MESOS_AGENT_PASSWORD': configs.get('agent_nodes').get('password')
        }
    )


def create_marathon_configs(configs, verb):
    for application in configs.get("applications"):

        _data_dict = {}
        for key in application:
            _data_dict.update({key.upper(): '{0}'.format(application.get(key))})

        _config = "{0}/{1}/{2}/marathon_config.json".format(
            META.MARATHON_TEMPLATE_DIR,
            application.get("name"),
            application.get("version")
        )

        _call_tpl = UseTemplate(
            template=_config + '.tpl',
            verb=verb
        )

        _call_tpl.create_new_file(new_file=_config, data_dict=_data_dict)


def trust_docker_registry(configs, verb):
    for host in configs.get('agent_nodes').get('address'):
        try:
            _session = SshSession(
                dest_host=host,
                dest_user=configs.get('agent_nodes').get('username'),
                dest_password=configs.get('agent_nodes').get('password'),
                verbosity=verb
            )

            agent_session = Shell(
                verb=verb,
                session=_session.login_with_password()
            )

            for registry in configs.get('private_registries'):
                docker_cert_dir = "{0}/{1}:{2}".format(
                    META.DOCKER_CERT_DIR,
                    registry.get('host'),
                    registry.get('port')
                )

                commands = dict(
                    create_docker_crt_dir="[ ! -d {0} ] && mkdir -p {0} || exit 0".format(
                        docker_cert_dir
                    ),
                    create_mesos_crt_dir="[ ! -d {0} ] && mkdir -p {0} || exit 0".format(
                        META.MESOS_CERT_DIR
                    ),
                    set_docker_crt="echo '{0}' > {1}/ca.crt".format(
                        registry.get('certificate'),
                        docker_cert_dir
                    ),
                    set_mesos_crt="echo '{0}' > {1}/`echo '{0}' | openssl x509 -hash -noout`.0".format(
                        registry.get('certificate'),
                        META.MESOS_CERT_DIR
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
