#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import subprocess
import time
import os
from .log import Log
from .log import LogNormal, LogError

from .utils import split_lines


class Shell():
    def __init__(self, session=None):
        self.remote = False
        self.session = session.invoke_shell() if session is not None else None

        self.retry_expire = int('60')
        self.retry_interval = int('1')

        self.log = Log()

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
            LogError(BAD_LOCAL_CMD_RETURN={"cmd": command, "return_code": return_code})
            for line in popen.stderr.readlines():
                LogError(STDERR={"stderr": line.decode('utf8')})
        else:
            LogNormal(NORM_LOCAL_CMD_RETURN={ "cmd": command })

    def remote(self, command):
        self.session.send(command + split_lines)
        self.log.output(log_message=command, header="[SHELL][remote]", show_state='complete')

        timeout = round(time.time()) + self.retry_expire
        while time.time() < timeout:
            time.sleep(self.retry_interval)

            if self.session.recv_ready():
                out = '\n'.join(split_lines(input_byte=self.session.recv(1024)))
                self.log.output(log_message=out, header="[SHELL][remote]")
