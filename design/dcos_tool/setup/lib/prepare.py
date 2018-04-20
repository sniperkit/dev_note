#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

from os.path import basename

from .template import UseTemplate
from .meta import MetaData
from .connect import Shell, SshSession
from .utils import is_empty_string

META = MetaData()


def ip_detect(bootstrap_host, verb):
    _ip_detect = UseTemplate(
        template='{0}/{1}.tpl'.format(META.DCOS_TEMPLATE_DIR, META.IP_DETECT),
        verb=verb
    )
    _ip_detect.create_new_file(
        new_file='{0}/{1}'.format(META.DCOS_TEMPORARY_DIR, META.IP_DETECT),
        data_dict={
            'ROUTE_DESTINATION': bootstrap_host
        }
    )


def aws_access_credential(id, secret, verb):
    template_path = '{0}/{1}.tpl'.format(META.AWS_TEMPLATE_DIR, basename(META.AWS_ACCESS_KEY_FILEPATH))

    UseTemplate(
        template=template_path, verb=verb
    ).create_new_file(
        new_file=META.AWS_ACCESS_KEY_FILEPATH,
        data_dict={
            'AWS_ACCESS_KEY_ID': id,
            'AWS_SECRET_ACCESS_KEY': secret}
    )


def _map_tfvars_if_any(configs):
    ddcos      = configs.get('dcos')
    dplatform  = configs.get('any')
    dbootstrap = dplatform.get('bootstrap_node')
    dmasters   = dplatform.get('master_nodes')
    dagents    = dplatform.get('agent_nodes')

    return {
        'DCOS_CLUSTER_NAME': ddcos.get('cluster_name'),
        'DCOS_DOWNLOAD_PATH': ddcos.get('archive'),
        'DCOS_IP_DETECT_SCRIPT': "{0}/{1}".format(META.DCOS_TEMPORARY_DIR, META.IP_DETECT),
        'DCOS_OAUTH_ENABLED' : ddcos.get('oauth_enabled'),
        'BOOTSTRAP_HOST': dbootstrap.get('address'),
        'BOOTSTRAP_SSH_PORT': dbootstrap.get('ports').get('ssh'),
        'BOOTSTRAP_WEB_PORT': dbootstrap.get('ports').get('web'),
        'BOOTSTRAP_USERNAME': dbootstrap.get('username'),
        'BOOTSTRAP_PASSWORD': dbootstrap.get('password'),
        'MESOS_MASTER_LIST': "\", \"".join(addr for addr in dmasters.get('address')),
        'MESOS_MASTER_COUNT': len(dmasters.get('address')),
        'MESOS_MASTER_USERNAME': dmasters.get('username'),
        'MESOS_MASTER_PASSWORD': dmasters.get('password'),
        'MESOS_AGENT_LIST': "\", \"".join(addr for addr in dagents.get('address')),
        'MESOS_AGENT_COUNT': len(dagents.get('address')),
        'MESOS_AGENT_USERNAME': dagents.get('username'),
        'MESOS_AGENT_PASSWORD': dagents.get('password')
    }


def _map_tfvars_if_aws(configs):
    ddcos           = configs.get('dcos')
    dplatform       = configs.get('aws')
    dbootstrap      = dplatform.get('bootstrap_node')
    dmasters        = dplatform.get('master_nodes')
    dagents         = dplatform.get('agent_nodes').get('private')
    dagents_public  = dplatform.get('agent_nodes').get('public')

    return {
        'DCOS_VERSION': ddcos.get('version'),
        'DCOS_OAUTH_ENABLED' : ddcos.get('oauth_enabled'),
        'SSH_KEY_NAME': dplatform.get('ssh_key_name'),
        'SSH_PRIVATE_KEY_FILEPATH': dplatform.get('ssh_private_key_filepath'),
        'MESOS_MASTER_COUNT': dmasters.get('count'),
        "MESOS_AGENT_COUNT": dagents.get('count'),
        "MESOS_PUBLIC_AGENT_COUNT": dagents.get('count'),
        'AWS_REGION': dplatform.get("region"),
        'AWS_BOOTSTRAP_INSTANCE_TYPE': dbootstrap.get("instance_type"),
        'AWS_BOOTSTRAP_INSTANCE_DISK_SIZE': dbootstrap.get("instance_disk_size_gb"),
        'AWS_MASTER_INSTANCE_TYPE': dmasters.get("instance_type"),
        'AWS_MASTER_INSTANCE_DISK_SIZE': dmasters.get("instance_disk_size_gb"),
        'AWS_AGENT_INSTANCE_TYPE': dagents.get("instance_type"),
        'AWS_AGENT_INSTANCE_DISK_SIZE': dagents.get("instance_disk_size_gb"),
        'AWS_PUBLIC_AGENT_INSTANCE_TYPE': dagents_public.get("instance_type"),
        'AWS_PUBLIC_AGENT_INSTANCE_DISK_SIZE': dagents_public.get("instance_disk_size_gb")
    }


def terraform_provision(filename, configs, verb):
    splatform = 'any' if is_empty_string(configs.get("platform")) else configs.get("platform")

    if splatform == 'aws':
        ddata = _map_tfvars_if_aws(configs)
    else:
        ddata = _map_tfvars_if_any(configs)

    UseTemplate(
        template="{}/{}_{}.tpl".format(META.TERRAFORM_TEMPLATE_DIR, splatform, filename),
        verb=verb
    ).create_new_file(
        new_file="{}/{}_{}".format(META.TERRAFORM_TEMPORARY_DIR, splatform, filename),
        data_dict=ddata
    )


def marathon_configs(configs, verb):
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
                verb=verb
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
