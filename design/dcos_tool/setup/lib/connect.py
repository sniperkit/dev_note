#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import subprocess
import time
import os
import paramiko
from .log import LogNormal, LogError

from .utils import split_lines


class SshSession():
    def __init__(self, dest_host, dest_user, dest_password):
        self.host=str(dest_host)
        self.username=str(dest_user)
        self.password=str(dest_password)

    def login_with_password(self):
        p_ssh = paramiko.SSHClient()
        p_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            p_ssh.connect(hostname=self.host, username=self.username, password=self.password)
            LogNormal(SSH_CONNECT={})

            return p_ssh

        except (paramiko.ssh_exception.SSHException, paramiko.ssh_exception.NoValidConnectionsError) as e:
            LogError(SSH_CONNECT={})
            LogError(STDERR={"stderr": e})

            return None


class Shell():
    def __init__(self, session=None):
        self.session = session.invoke_shell() if session is not None else None

        self.retry_expire = int('60')
        self.retry_interval = int('1')

    @staticmethod
    def local(command, ignore_err=False):
        popen = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        while True:
            line = popen.stdout.readline()

            if line != b'':
                os.write(1, line)
            else:
                break

        popen.stdout.close()
        return_code = popen.wait()

        if not return_code == 0 and not ignore_err:
            LogError(LOCAL_CMD_RETURN={"cmd": command, "return_code": return_code})
            for line in popen.stderr.readlines():
                LogError(STDERR={"stderr": line.decode('utf8')})
        else:
            LogNormal(LOCAL_CMD_RETURN={"cmd": command})

    def remote(self, command):
        chn = self.session.get_transport().open_session()

        chn.settimeout(10800)
        chn.exec_command(command)

        while not chn.exit_status_ready():
            time.sleep(self.retry_interval)

            if chn.recv_ready():
                data_buffer = '\n'.join(split_lines(input_byte=chn.recv(1024)))

                while data_buffer:
                    LogNormal(STDOUT={"stdout": data_buffer})
                    data_buffer = '\n'.join(split_lines(input_byte=chn.recv(1024)))

        if chn.recv_exit_status() is 0:
            LogNormal(REMOTE_CMD_RETURN={"cmd": command})
        else:
            LogError(REMOTE_CMD_RETURN={"cmd": command, "return_code": chn.recv_exit_status()})
