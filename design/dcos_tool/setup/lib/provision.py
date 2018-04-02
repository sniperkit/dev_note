#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from .connect import Shell, SshSession
from .meta import MetaData


def provision_bootstrap(configs):
    mdata = MetaData()
    bootstrap_session = Shell()

    command = "cd {0} && /bin/bash ./dcos_generate_config.sh".format(mconfig.BOOTSTRAP_ROOT)
    bootstrap_session.local(command)

    command = "docker run -d -p {0}:80 -v {1}/genconf/serve:/usr/share/nginx/html:ro nginx".format(
        configs.get('bootstrap_node').get('port'),
        mdata.BOOTSTRAP_ROOT
    )
    bootstrap_session.local(command)


def provision_master(configs):
    mdata = MetaData()

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
                    configs.get('bootstrap_node').get('port'), mdata.BOOTSTRAP_ROOT)
                command = "sed -E -i 's#{0}#& \\n{1}#' /tmp/dcos_install.sh".format(sed_find, sed_replace)
                master_session.local(command)

            command = "/bin/bash /tmp/dcos_install.sh master"
            master_session.remote(command=command)

        finally:
            if master_session.session:
                master_session.session.close()


def provision_agent(configs):
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
