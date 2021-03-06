#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import subprocess
import time
import paramiko

from .utils import remove_ansi_escape
from .log import LogNormal, LogError, LogWarn
from .utils import split_lines


class SshSession():
    def __init__(self, dest_host, dest_user, dest_password, verb):
        self.host=str(dest_host)
        self.username=str(dest_user)
        self.password=str(dest_password)

        self.verb = verb

    def login_with_password(self):
        p_ssh = paramiko.SSHClient()
        p_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            p_ssh.connect(hostname=self.host, username=self.username, password=self.password)
            LogNormal(
                self.verb,
                INFO={"message": "create ssh session"},
                SSH_CONNECT={})

            return p_ssh

        except (paramiko.ssh_exception.SSHException, paramiko.ssh_exception.NoValidConnectionsError) as e:
            LogError(self.verb, SSH_CONNECT={})
            LogError(self.verb, STDERR={"stderr": e})

            return None


class Shell():
    def __init__(self, verb, session=None):
        self.session = session.invoke_shell() if session is not None else None
        self.verb = verb

        self.retry_expire = int('60')
        self.retry_interval = int('1')

    def local(self, command, info, set_dir=None, warn=False):
        popen = subprocess.Popen(command,
                                 cwd=set_dir, shell=True,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)

        loops = 0
        retry = 120
        while True:
            time.sleep(0.2)
            loops = loops + 1
            if loops > retry: break

            line = popen.stdout.readline().strip()
            line = remove_ansi_escape(line.decode("utf-8"), clear=True)
            if line != '':
                LogNormal(STDOUT={'stdout': line}, verb=self.verb)
                loops = 0

            if not line and popen.poll() is not None: break

        popen.stdout.close()
        return_code = popen.wait()

        if not return_code == 0 and not warn:
            LogError(
                self.verb,
                INFO={"message": info},
                LOCAL_CMD_RETURN={"cmd": command, "return_code": return_code}
            )
            for line in popen.stderr.readlines():
                LogError(
                    self.verb,
                    STDERR={"stderr": line.decode('utf8')})
        elif not return_code == 0 and warn:
            LogWarn(
                self.verb,
                INFO={"message": info}
            )
            for line in popen.stderr.readlines():
                LogError(
                    self.verb,
                    STDERR={"stderr": line.decode('utf8')})
        else:
            LogNormal(
                self.verb,
                INFO={"message": info},
                LOCAL_CMD_RETURN={"cmd": command})

        return return_code

    def remote(self, command, info):
        chn = self.session.get_transport().open_session()

        chn.settimeout(10800)
        chn.exec_command(command)

        while not chn.exit_status_ready():
            time.sleep(self.retry_interval)

            if chn.recv_ready():
                data_buffer = '\n'.join(split_lines(input_byte=chn.recv(1024)))

                while data_buffer:
                    LogNormal(
                        self.verb,
                        INFO={"message": "getting data"},
                        STDOUT={"stdout": data_buffer}
                    )
                    data_buffer = '\n'.join(split_lines(input_byte=chn.recv(1024)))

        if chn.recv_exit_status() is 0:
            LogNormal(
                self.verb,
                INFO={"message": info},
                REMOTE_CMD_RETURN={"cmd": command}
            )
        else:
            LogError(
                self.verb,
                INFO={"message": info},
                REMOTE_CMD_RETURN={"cmd": command, "return_code": chn.recv_exit_status()}
            )
