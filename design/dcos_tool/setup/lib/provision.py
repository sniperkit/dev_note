#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from .connect import Shell, SshSession
from .meta import MetaData


class BootstrapNode:
    def __init__(self, configs, verbosity):
        self.configs = configs
        self.verbosity = verbosity
        self.meta = MetaData()
        self.shell = Shell(self.verbosity)

        self.generate_config()
        self.start_web_service()

    def generate_config(self):
        cmd = "cd {0} && /bin/bash ./dcos_generate_config.sh".format(
            self.meta.BOOTSTRAP_ROOT
        )

        self.shell.local(cmd, info="bootstrap configs")

    def start_web_service(self):
        cmd = "docker run -d -p {0}:80 -v {1}/genconf/serve:/usr/share/nginx/html:ro nginx".format(
            self.configs.get('bootstrap_node').get('port'),
            self.meta.BOOTSTRAP_ROOT
        )

        self.shell.local(cmd, info="start web service")


class MasterNode:
    def __init__(self, configs, verbosity):
        self.verbosity=verbosity
        self.meta = MetaData()
        self.configs = configs

        self.bootstrap()

    def bootstrap(self):
        for host in self.configs.get('master_nodes').get('addr'):
            try:
                _session = SshSession(
                    dest_host=host,
                    dest_user=self.configs.get('master_nodes').get('username'),
                    dest_password=self.configs.get('master_nodes').get('password'),
                    verbosity=self.verbosity)

                master_session = Shell(verbosity=self.verbosity,
                                       session=_session.login_with_password())

                command = "curl -o /tmp/dcos_install.sh http://{0}:{1}/dcos_install.sh".format(
                    self.configs.get('bootstrap_node').get('addr'),
                    self.configs.get('bootstrap_node').get('port'))
                master_session.remote(command=command, info="download provision script")

                if self.configs.get('bootstrap_node').get('addr') == host:
                    sed_find = "^systemctl restart docker"
                    sed_replace = "docker run -d -p {0}:80 -v {1}/genconf/serve:/usr/share/nginx/html:ro nginx".format(
                        self.configs.get('bootstrap_node').get('port'), self.meta.BOOTSTRAP_ROOT)

                    command = "sed -E -i 's#{0}#& \\n{1}#' /tmp/dcos_install.sh".format(sed_find, sed_replace)
                    master_session.local(command, info="set install script")

                command = "/bin/bash /tmp/dcos_install.sh master"
                master_session.remote(command=command, info="provision master node")

            finally:
                if master_session.session:
                    master_session.session.close()


class AgentNode:
    def __init__(self, configs, verbosity):
        self.verbosity = verbosity
        self.configs = configs
        self.meta = MetaData()

    def bootstrap(self):
        for host in self.configs.get('agent_nodes').get('addr'):
            try:
                _session = SshSession(
                    dest_host=host,
                    dest_user=self.configs.get('agent_nodes').get('username'),
                    dest_password=self.configs.get('agent_nodes').get('password'),
                    verbosity=self.verbosity
                )

                agent_session = Shell(
                    verbosity=self.verbosity,
                    session=_session.login_with_password())

                commands = dict(
                    download_install_script="curl -o /tmp/dcos_install.sh http://{0}:{1}/dcos_install.sh".format(
                        self.configs.get('bootstrap_node').get('addr'),
                        self.configs.get('bootstrap_node').get('port')
                    ),
                    run_install="sudo /bin/bash /tmp/dcos_install.sh slave"
                )

                agent_session.remote(command=commands.get("download_install_script"), info="download install script")
                agent_session.remote(command=commands.get("run_install"), info="run install script")

            finally:
                if agent_session.session:
                    agent_session.session.close()

    def trust_registry(self):
        for host in self.configs.get('agent_nodes').get('addr'):
            try:
                _session = SshSession(
                    dest_host=host,
                    dest_user=self.configs.get('agent_nodes').get('username'),
                    dest_password=self.configs.get('agent_nodes').get('password'),
                    verbosity=self.verbosity
                )

                agent_session = Shell(
                    verbosity=self.verbosity,
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
                                         info="create dcos cert-directory if not exist")
                    agent_session.remote(command=commands.get("create_mesos_crt_dir"),
                                         info="create mesos cert-directory if not exist")
                    agent_session.remote(command=commands.get("set_docker_crt"),
                                         info="set docker trust registry")
                    agent_session.remote(command=commands.get("set_mesos_crt"),
                                         info="set mesos trust docker download")

            finally:
                if agent_session.session:
                    agent_session.session.close()
