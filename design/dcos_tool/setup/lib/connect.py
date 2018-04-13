#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import subprocess
import time
import os
import paramiko

from .log import LogNormal, LogError
from .utils import split_lines


class SshSession():
    def __init__(self, dest_host, dest_user, dest_password, verbosity):
        self.host=str(dest_host)
        self.username=str(dest_user)
        self.password=str(dest_password)

        self.verbosity = verbosity

    def login_with_password(self):
        p_ssh = paramiko.SSHClient()
        p_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            p_ssh.connect(hostname=self.host, username=self.username, password=self.password)
            LogNormal(
                self.verbosity,
                INFO={"message": "create ssh session"},
                SSH_CONNECT={})

            return p_ssh

        except (paramiko.ssh_exception.SSHException, paramiko.ssh_exception.NoValidConnectionsError) as e:
            LogError(self.verbosity, SSH_CONNECT={})
            LogError(self.verbosity, STDERR={"stderr": e})

            return None


class Shell():
    def __init__(self, verbosity, session=None):
        self.session = session.invoke_shell() if session is not None else None
        self.verbosity = verbosity

        self.retry_expire = int('60')
        self.retry_interval = int('1')

    def local(self, command, info, ignore_err=False):
        popen = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        while True:
            line = popen.stdout.readline()

            if line != b'':
                os.write(1, line + b'\n')
            else:
                break

        popen.stdout.close()
        return_code = popen.wait()

        if not return_code == 0 and not ignore_err:
            LogError(
                self.verbosity,
                INFO={"message": info},
                LOCAL_CMD_RETURN={"cmd": command, "return_code": return_code}
            )
            for line in popen.stderr.readlines():
                LogError(
                    self.verbosity,
                    INFO={"message": ''},
                    STDERR={"stderr": line.decode('utf8')})
        else:
            LogNormal(
                self.verbosity,
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
                        self.verbosity,
                        INFO={"message": "getting data"},
                        STDOUT={"stdout": data_buffer}
                    )
                    data_buffer = '\n'.join(split_lines(input_byte=chn.recv(1024)))

        if chn.recv_exit_status() is 0:
            LogNormal(
                self.verbosity,
                INFO={"message": info},
                REMOTE_CMD_RETURN={"cmd": command}
            )
        else:
            LogError(
                self.verbosity,
                INFO={"message": info},
                REMOTE_CMD_RETURN={"cmd": command, "return_code": chn.recv_exit_status()}
            )
