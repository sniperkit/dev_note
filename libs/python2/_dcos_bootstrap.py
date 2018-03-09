#!/bin/usr/env python2
"""
Usage:
    bootstrap (bootstrap | master)

Options:
    -h                  show help
"""
from docopt import docopt

import os
import sys
import subprocess
import time
import urllib2
from mako.template import Template

#**** DEPENENCY ****#
'''
Over 10GB of free disk space and 8GB of RAM
[docker, python-mako<<tested noarch-0.8.1-2.el7>>, python-paramiko<< tested noarch-2.1.1-2.el7 >>]
[Python 3.6 <<??>>]

yum -y install epel-release && 
yum -y install python-docopt python-mako python-paramiko

if master:
groupadd nogroup

'''


class Utils():
    def __init__(self):
        self.debug = False

    @staticmethod
    def is_files_exist(file_list):
        """
        Check all files exist
        :return: bool
        """
        for _file in file_list:
            if not os.path.isfile(_file):
                return False
            else:
                continue

    @staticmethod
    def write_to_file(path, lines):
        """
        write to file
        :param path: str
        :param lines: list
        :return: bool
        """
        try:
            _dir = os.path.dirname(path)
            if not os.path.isdir(_dir):
                Utils.log_this(log=_dir, tag="[DIR][create]")
                os.mkdir(_dir)

            with open(path, 'w') as fnew:
                fnew.write('\n'.join(lines))

        except IOError:
            return False


    @staticmethod
    def generate_from_mako(filein, fileout, renders, debug=False):
        """
        Generate from mako template
        :param filein: str
        :param fileout: str
        :param renders: dict
        :param debug: bool
        :return: bool
        """
        script_lines = Template(filename=filein).render(render=renders)
        if debug: Utils.log_this(log=script_lines, tag="[MAKO][script]")

        try:
            Utils.log_this(log=filein, tag="[MAKO][generating]")

            _dir=os.path.dirname(fileout)
            if not os.path.isdir(_dir):
                os.makedirs(_dir)

            with open(fileout, "w+") as f:
                f.write(script_lines)

            Utils.log_this(log=fileout, tag="[MAKO][generated]")

        except IOError:
            return False

    @staticmethod
    def create_ssh_keypair(dest, force=False):
        Utils.log_this(log="ssh keypair", tag="[SSH][create]")

        cmd = 'ssh-keygen -b 2048 -t rsa -f {0} -q -N ""'.format(dest)
        if force:
            cmd = "'y\n'|" + cmd
        else:
            if os.path.isfile(dest):
                Utils.log_this(log="pass", tag="[SSH][create]")
                return True

        _, stderr = Utils.cmd_sh(cmd)

        return False if stderr else True

    @staticmethod
    def add_ssh_known_host(host):
        f_known_host = os.path.expanduser('~/.ssh/known_hosts')

        d_known_host = os.path.dirname(f_known_host)
        if not os.path.isdir(d_known_host):
            os.mkdir(d_known_host)

        _lines = []

        if os.path.isfile(f_known_host):
            _file = open(f_known_host, "r")
            # FIXME: cannot handle big file
            _lines = _file.readlines()
            _file.close()

        Utils.log_this(log="checking existing known host", tag="[SSH]")
        _file = open(f_known_host, "w+")
        for line in _lines:
            if host not in line:
                _file.write(line)
            else:
                Utils.log_this(log="found {0}".format(host), tag="[SSH]")

        cmd = "ssh-keyscan -t rsa {0}".format(host)
        stdout, _ = Utils.cmd_sh(cmd)

        if stdout:
            Utils.log_this(log="update known host", tag="[SSH]")
            Utils.log_this(log=stdout, timestamp=False)
            _file.write(stdout + '\n')

        return _file.close()

    @staticmethod
    def is_ssh_key_auth(host, port, user, private_key):
        Utils.log_this(log="checking", tag="[SSH][Authentication]")
        Utils.log_this(log="ensure to place key to destination host", timestamp=False)
        Utils.log_this(
            log="scp -P {3} {0}.pub {1}@{2}:~/.ssh/authorized_keys".format(
                os.path.abspath(private_key), user, host, port
            ),
            timestamp=False
        )

        cmd = 'ssh -o PasswordAuthentication=no -o Batchmode=yes -i {0} {1}@{2} -p {3} "whoami"'.format(
            private_key, user, host, port)
        Utils.log_this(log=cmd, tag="[SSH][cmd]")

        stdout, _ = Utils.cmd_sh(cmd, ignore_err=False)
        return True if stdout==user else False

    # @staticmethod
    # def sftp_upload(host, port, username, key, src, dest):
    #     import paramiko
    #
    #     Utils.log_this(log=src, tag="[SFTP][from]")
    #
    #     _key = paramiko.RSAKey.from_private_key_file(key)
    #     _transport = paramiko.Transport((host, port))
    #     _transport.connect(username, pkey=_key)
    #
    #     _sftp = paramiko.SFTPClient.from_transport(_transport)
    #     _sftp.put(src, dest)
    #
    #     _sftp.close()
    #     _transport.close()
    #
    #     Utils.log_this(log=dest, tag="[SFTP][to]")

    # @staticmethod
    # def get_public_ip_interface():
    #     # TODO
    #     return 'enp0s3'
    #
    # @staticmethod
    # def get_public_ip():
    #     # TODO
    #     return '34.217.78.154'

    @staticmethod
    def cmd_sh(cmd, ignore_err=True, info=False, debug=False):
        """
        Run shell command
        :param cmd: str
        :param debug: bool
        :return: str, str
        """
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()


        if stdout:
            if info or debug:
                Utils.log_this(log=stdout, tag="[SHELL][stdout]")

        if stderr:
            if debug or not ignore_err:
                Utils.log_this(tag="[SHELL][ERR]")
                Utils.log_this(stderr, timestamp=False)
            if not ignore_err:
                Utils.log_this(log="... exiting", tag="[SHELL][ERR]")
                sys.exit()

        if not stdout and not stderr:
            if debug:
                Utils.log_this(log="empty", tag="[SHELL][std]")

        return stdout.rstrip("\n"), stderr.rstrip("\n")

    @staticmethod
    def yum_install(pkg):
        """
        install yum packages
        :param pkg: str
        :return: bool
        """
        cmd = "yum install -y {0}".format(pkg)
        _, stderr = Utils.cmd_sh(cmd)

        return False if stderr else True

    @staticmethod
    def start_service(service):
        """
        start system service
        :param service: str
        :return: bool
        """
        Utils.log_this(log=service, tag="[Service][start]")
        _, stderr = Utils.cmd_sh('systemctl start {0}'.format(service))

        return False if stderr else True

    @staticmethod
    def enable_service(service):
        """
        enable system service
        :param service: str
        :return: bool
        """
        Utils.log_this(log=service, tag="[Service][enable]")
        _, stderr = Utils.cmd_sh('systemctl enable {0}'.format(service))

        return False if stderr else True

    @staticmethod
    def log_this(log='', tag=None, timestamp=True):
        _time = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(time.time())) + ' ' if timestamp else ''
        _tag = tag + ' ' if tag is not None else ''

        print("{0}{1}{2}".format(_time, _tag, log))

    @staticmethod
    def download_url(url, filepath):
        Utils.log_this(log=url, tag="[DOWNLOAD][from]")

        try:
            data = urllib2.urlopen(url).read()
            with open(filepath, "wb") as f:
                f.write(data)

            Utils.log_this(log=filepath, tag="[DOWNLOAD][to]")

        except urllib2.HTTPError as e:
            Utils.log_this(log=e.code, tag="[DOWNLOAD][HTTPError]")

        except IOError as e:
            Utils.log_this(log="fail to write to file", tag="[DOWNLOAD][IOError]")
            Utils.log_this(log=str(e))

    @staticmethod
    def reboot():
        Utils.log_this(log="please reboot system and run again ... exiting", tag="[REBOOT]")
        sys.exit()


class Bootstrap():
    def __init__(self):
        self.genconf = './genconf' #this must be relative path
        self.serve = self.genconf + '/serve'

        self.dcos_install = 'dcos_install.sh'

        self.deploy_over_web = True

        self.ssh_key_path = self.genconf + '/ssh_key'
        self.ssh_user = 'admin'
        self.ssl_pass = 'test'

        self.configs = self.genconf + '/config.yaml'
        self.configs_tpl = self.genconf + '/config.yaml.mako'

        self.ip_detect = self.genconf + '/ip-detect'
        self.ip_detect_tpl = self.genconf + '/ip-detect.mako'

        self.container_script = './dcos_generate_config.sh'

        self.bootstrap_container = 'bootstrap'
        self.bootstrap_ip = "34.217.64.28"
        self.bootstrap_port = 10080  #TODO: master:adminrouter require p:80
        self.cluster = 'testcluster'
        self.masters = ["54.187.114.0"]
        self.agents = ["2.2.2.2"]
        self.resolvers = ["8.8.8.8", "8.8.4.4"]

        self.dependencies = [self.configs_tpl,
                             self.ip_detect_tpl]

    def create_ip_detect_file(self):
        Utils.log_this(log="create ip detect", tag="[TEMPLATE]")

        settings = dict(route_destination=self.bootstrap_ip)
        return Utils.generate_from_mako(self.ip_detect_tpl, self.ip_detect, settings)

    def run_ip_detect(self):
        cmd = 'sh {0}'.format(self.ip_detect)
        self.bootstrap_ip, _ = Utils.cmd_sh(cmd)

        if self.bootstrap_ip: Utils.log_this(log=self.bootstrap_ip, tag="[IP_DETECT]")
        else: Utils.log_this(log="None", tag="[IP_DETECT]")

        return self.bootstrap_ip

    def create_config_file(self):
        settings = dict(
            public_ip=self.bootstrap_ip,
            port=self.bootstrap_port,
            clustername=self.cluster,
            masters=self.masters,
            resolvers=self.resolvers,
            ip_detect=self.ip_detect,
            ssh_keypath=self.ssh_key_path,
            ssh_user=self.ssh_user
        )

        return Utils.generate_from_mako(self.configs_tpl, self.configs, settings)

    def create_bootstrap_image(self):
        Utils.log_this(log="bootstrap image", tag="[BOOTSTRAP][create]")
        cmd = 'sh {0}'.format(self.container_script)
        Utils.cmd_sh(cmd)

    def run_bootstrap_container(self):
        Utils.log_this(log="run container", tag="[BOOTSTRAP]")

        genconf_abspath = os.path.abspath(self.genconf)
        cmd = 'docker run -d --name={0} -p {1}:80 -v {2}/serve:/usr/share/nginx/html:ro nginx'.format(
            self.bootstrap_container,
            self.bootstrap_port,
            genconf_abspath)

        Utils.cmd_sh(cmd, debug=True)
        Utils.log_this("curl -O http://{bootstrap_node}:{bootstrap_port}/{dcos_install}".format(
            bootstrap_node=self.bootstrap_ip,
            bootstrap_port=self.bootstrap_port,
            dcos_install=self.dcos_install),
            tag="[BOOTSTRAP][container]"
        )

    @staticmethod
    def is_docker_container_exist(container_name):
        """
        Check is docker container exist
        :param container_name: str
        :return: bool
        """
        cmd = 'docker ps -a --format "{{.Names}}" | grep {0}'.format(container_name)
        return Utils.cmd_sh(cmd)

    @staticmethod
    def is_docker_container_running(container_name):
        """
        Check is docker container running
        :param container_name: str
        :return: bool
        """
        cmd = 'docker ps --format "{{.Names}}" | grep {0}'.format(container_name)
        return Utils.cmd_sh(cmd)

    def stop_docker_container(self, container_name):
        """
        Stop docker container
        :param container_name: str
        :return: bool
        """
        if self.is_docker_container_running(container_name):
            Utils.log_this(log=container_name, tag="[DOCKER][stop]")
            cmd = 'docker stop {0}'.format(container_name)
            return Utils.cmd_sh(cmd)
        else:
            Utils.log_this(log="pass", tag="[DOCKER][stop]")
            return False

    def remove_docker_container(self, container_name):
        """
        Stop and remove docker container
        :param container_name: str
        :return: bool
        """
        self.stop_docker_container(container_name)

        if self.is_docker_container_exist(container_name):
            Utils.log_this(log=container_name, tag="[DOCKER][remove]")

            cmd = 'docker rm {0}'.format(container_name)
            return Utils.cmd_sh(cmd)
        else:
            Utils.log_this(log="pass", tag="[DOCKER][remove]")
            return False

    def setup(self):
        Utils.create_ssh_keypair(dest=self.ssh_key_path)

        for master in self.masters:
            Utils.add_ssh_known_host(master)
            # **** development only **** #
            dev_mode = DevMode()
            dev_mode.setup()
            # **** ================ **** #
            # Utils.is_ssh_key_auth(master, 22, self.ssh_user, self.ssh_key_path)

        Utils.is_files_exist(self.dependencies)
        self.create_ip_detect_file()
        self.create_config_file()

        self.remove_docker_container(self.bootstrap_container)
        self.create_bootstrap_image()

        self.run_bootstrap_container()


# TODO: this should be a service in master#
class Agent():
    def __init__(self):
        self.install_src_dir = '/tmp'

    def web_dcos_install(self, host):
        bstrp = Bootstrap()

        cmd = "ssh -i {key} -p {port} {user}@{host} \"" \
              "cd {dir} && " \
              "sudo curl -O http://{bootstrap_node}:{bootstrap_port}/{dcos_install}" \
              "\"".format(host=host,
                          port=22,
                          key=bstrp.ssh_key_path,
                          user=bootstrap.ssh_user,
                          dir=self.install_src_dir,
                          bootstrap_node=bstrp.bootstrap_ip,
                          bootstrap_port=bstrp.bootstrap_port,
                          dcos_install=bstrp.dcos_install)

        Utils.cmd_sh(cmd, info=True)

    # FIXME: some service not running as expected
    def ssh_dcos_install(self, host):
        bstrp = Bootstrap()

        cmd = "scp -i {key} -P {port} {src_dir}/{src_script} {user}@{host}:./ && " \
              "ssh -i {key} -p {port} {user}@{host} mv ./{src_script} {dest_dir}".format(
            host=host,
            port=22,
            key=bstrp.ssh_key_path,
            user=bootstrap.ssh_user,
            src_dir=bstrp.serve,
            src_script=bstrp.dcos_install,
            dest_dir=self.install_src_dir,
        )
        Utils.cmd_sh(cmd, info=True, ignore_err=False)

    def deploy_node(self, host, role):
        bstrp = Bootstrap()

        cmd = "ssh -i {key} -p {port} {user}@{host} \"" \
              "sudo bash {dir}/{dcos_install} {role}" \
              "\"".format(host=host,
                          port=22,
                          key=bstrp.ssh_key_path,
                          user=bootstrap.ssh_user,
                          dir=self.install_src_dir,
                          bootstrap_node=bstrp.bootstrap_ip,
                          bootstrap_port=bstrp.bootstrap_port,
                          dcos_install=bstrp.dcos_install,
                          role=role)
        Utils.cmd_sh(cmd, info=True)

    def setup_master(self):
        # **** deploy node ********************************** #
        for master in bootstrap.masters:
            Utils.log_this(log=master, tag="[MASTER][deploy]")
            self.web_dcos_install(master)
            # self.ssh_dcos_install(master)
            self.deploy_node(master, "master")

    # def setup_agent(self):
    #     # **** deploy node ********************************** #
    #     for agent in bootstrap.agents:
    #         Utils.log_this(log=agent, tag="[AGENT][deploy]")
    #         self.web_dcos_install(agent)
    #         # self.ssh_dcos_install(master)
    #         self.deploy_node(agent, "agent")


class Docker():
    def __init__(self):
        self.overlay_conf = '/etc/modules-load.d/overlay.conf'
        self.docker_repo = '/etc/yum.repos.d/docker.repo'
        self.docker_systemd = '/etc/systemd/system/docker.service.d/override.conf'

    @staticmethod
    def is_overlayfs():
        cmd = 'lsmod | grep overlay'
        stdout, _ = Utils.cmd_sh(cmd)
        return stdout

    def enable_overlayfs(self):
        if self.is_overlayfs():
            Utils.log_this(log="enabled", tag="[OVERLAYFS]")
        else:
            Utils.log_this(log="set enable", tag="[OVERLAYFS]")
            with open(self.overlay_conf, "w") as fnew:
                fnew.write("overlay")

            Utils.reboot()

    def create_yum_repo(self):
        lines = [
            '[dockerrepo]',
            'name=Docker Repository',
            'baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/',
            'enabled=1',
            'gpgcheck=1',
            'gpgkey=https://yum.dockerproject.org/gpg'
        ]

        Utils.write_to_file(self.docker_repo, lines)

    def create_systemd(self):
        lines = [
            '[Service]',
            'ExecStart=',
            'ExecStart=/usr/bin/dockerd --storage-driver=overlay'
        ]

        Utils.write_to_file(self.docker_systemd, lines)

    def setup(self):
        self.enable_overlayfs()
        self.create_yum_repo()
        self.create_systemd()
        Utils.yum_install('docker-engine-1.13.1')
        Utils.yum_install('docker-engine-selinux-1.13.1')
        Utils.start_service('docker')
        Utils.enable_service('docker')


class DevMode():
    def __init__(self):
        self.universal_user = 'admin'
        self.universal_pass = 'test'
        self.yum_dependencies = ["sshpass"]

    @staticmethod
    def yum_install(package):
        Utils.log_this(log=package, tag="[DEV_MODE][YUM][install]")
        cmd = "yum -y install {0}".format(package)
        Utils.cmd_sh(cmd)

    @staticmethod
    def create_user(username, password):
        Utils.log_this(log=username, tag="[DEV_MODE][User][create]")
        cmds = [
            "id -u {0} &>/dev/null || useradd {0}".format(username),
            "echo {0}:{1} | chpasswd".format(username, password)
        ]
        for cmd in cmds:
            Utils.cmd_sh(cmd, ignore_err=False)

    @staticmethod
    def set_ssh_auth(host, port, user, password, pub_key):
        Utils.log_this(log="setup ssh authorized_keys", tag="[DEV_MODE][SSH]")

        cmd = "sshpass -p '{passwd}' ssh -p {port} {user}@{host} \"" \
              "echo {key} > /home/{user}/.ssh/authorized_keys &&" \
              "chmod 0700 /home/{user}/.ssh &&" \
              "chmod 0640 /home/{user}/.ssh/authorized_keys" \
              "\"".format(
            host=host,
            port=port,
            user=user,
            passwd=password,
            key=pub_key.rstrip('\n')
        )
        Utils.log_this(log=cmd, tag="[DEV_MODE][CMD]")
        Utils.cmd_sh(cmd)

    def setup(self):
        for pkg in self.yum_dependencies:
            self.yum_install(pkg)

        bstrap = Bootstrap()
        self.create_user(bstrap.ssh_user, bstrap.ssl_pass)

        with open(bstrap.ssh_key_path + '.pub') as fopen:
            pub_key = fopen.read()

        for host in bstrap.masters:
            self.set_ssh_auth(host, 22, self.universal_user, self.universal_pass, pub_key)


if __name__ == "__main__":
    args = docopt(__doc__)

    Utils.log_this(tag="[START]")
    start = time.time()

    docker = Docker()
    docker.setup()

    if args.get("bootstrap"):
        bootstrap = Bootstrap()
        bootstrap.setup()

    # agent = Agent()
    # agent.setup_master()

    Utils.log_this('%.2f s' % (time.time() - start), tag="[FINISH]")

# TODO
#
# create_ip_detect():
#
# create_installer_script():
#
# run_installer_script():
#
# docker_run:
#
# install_agent_node():
#
# setup_cli(token): # figure way to pass interaction token setup
#
# get_token():
#   """
#   Get token from agent node
#   :param:
#   :return: str
#   """