#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import subprocess
import time


class Shell():
    def __init__(self, session=None):
        self.remote = False
        self.session = session.invoke_shell() if session is not None else None

        self.retry_expire = int('60')
        self.retry_interval = int('1')

        self.linebreak = str('\n')

    def local(self, command):
        pid = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        lines = []
        for line in pid.stdout.readlines():
            lines.append(line)

        return lines

    def remote(self, command):
        self.session.send(command + self.linebreak)

    def response_byte(self):
        timeout = round(time.time()) + self.retry_expire

        while time.time() < timeout:
            time.sleep(self.retry_interval)

            if self.session.recv_ready():
                return self.session.recv(1024)

    def response_lines(self):
        lines = []
        for line in self.response_byte().decode('utf8').split(self.linebreak):
            lines.append(line.strip())

        return lines

