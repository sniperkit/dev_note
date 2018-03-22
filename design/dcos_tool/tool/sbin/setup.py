#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-

import argparse
import yaml
import paramiko
import time


class Log():
    def __init__(self):
        self.fg_reset = '\033[0m'
        self.fg_bold = '\033[1m'
        self.fg_green = '\033[92m'
        self.fg_red = '\033[91m'

    def output(self, log_message, header, show_state='', timestamp=True):
        import datetime

        ts = datetime.datetime.now().strftime("%a, %d %B %Y %I:%M:%S") + ' '
        ts = ts if timestamp is True else ''

        msg_out = ''
        if show_state == 'error': msg_out = " ... " + self.fg_red + 'ERROR' + self.fg_reset
        if show_state == 'complete': msg_out = " ... " + self.fg_green + 'COMPLETE' + self.fg_reset
        if show_state == 'ok': msg_out = " ... " + self.fg_green + 'OK' + self.fg_reset

        print(self.fg_bold + ts + header + self.fg_reset + ' ' + log_message + msg_out)


class SshSession():
    def __init__(self, dest_host, dest_user, dest_password):
        self.host=str(dest_host)
        self.username=str(dest_user)
        self.password=str(dest_password)
        self.log=Log()

    def login_with_password(self):
        p_ssh = paramiko.SSHClient()
        p_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            p_ssh.connect(hostname=self.host, username=self.username, password=self.password)
            self.log.output(log_message='connect', header='[SESSION][ssh]', show_state='ok')

            return p_ssh

        except (paramiko.ssh_exception.SSHException, paramiko.ssh_exception.NoValidConnectionsError) as e:
            self.log.output(log_message='connect', header='[SESSION][ssh]', show_state='error')
            self.log.output(log_message=str(e), header='[SESSION][error]')

            return None


class Shell():
    def __init__(self, session):
        self.session = session.invoke_shell()

        self.retry_expire = int('60')
        self.retry_interval = int('1')

        self.linebreak = str('\n')

    def input(self, input):
        self.session.send(input + self.linebreak)

    def _response_byte(self):
        timeout = round(time.time()) + self.retry_expire

        while time.time() < timeout:
            time.sleep(self.retry_interval)

            if self.session.recv_ready():
                return self.session.recv(1024)

    def response_lines(self):
        lines = []

        for line in self._response_byte().decode('utf8').split(self.linebreak):
            lines.append(line.strip())

        return lines



parser = argparse.ArgumentParser(description='Deploy Cluster')
parser.add_argument('--config', help='config file')
args = parser.parse_args()

# print(args.config)

# PARSE YAML
# with open(args.config) as f_stream:
#     _config=yaml.load(f_stream)
# print(_config.get('a list')[0])

# SSH CONNECT
# p_session=SshSession(dest_host="192.168.201.112", dest_password="", dest_user="root")

# SSH COMMAND
# p_shell=Shell(session=p_session.login_with_password())
# p_shell.input(input="echo 'hello'")
# print(p_shell.response_lines())


