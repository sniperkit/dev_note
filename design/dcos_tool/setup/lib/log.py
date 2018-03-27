#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-


class Log:
    def __init__(self):
        self.fg_reset = '\033[0m'
        self.fg_bold = '\033[1m'
        self.fg_lightgrey = '\033[37m'
        self.fg_red = '\033[91m'
        self.fg_green = '\033[92m'

    def output(self, log_message, header, show_state='', timestamp=True):
        import datetime

        ts = datetime.datetime.now().strftime("%a, %d %B %Y %I:%M:%S") + ' '
        ts = ts if timestamp is True else ''

        msg_out = ''
        if show_state == 'error': msg_out = " ... " + self.fg_red + 'ERROR' + self.fg_reset
        if show_state == 'normal': msg_out = " ... " + self.fg_green + 'NORMAL' + self.fg_reset
        if show_state == 'complete': msg_out = " ... " + self.fg_green + 'COMPLETE' + self.fg_reset
        if show_state == 'ok': msg_out = " ... " + self.fg_green + 'OK' + self.fg_reset

        if show_state == 'error' or show_state == 'err_nostate' or header == '[ERROR]':
            print(self.fg_bold + ts + header + ' ' + log_message + msg_out + self.fg_reset)
        else:
            print(self.fg_lightgrey + ts + header + ' ' + log_message + self.fg_reset + msg_out)


class LogError:
    def __init__(self, **kwargs):
        self.log = Log()
        self.stderr = kwargs.get('STDERR', None)
        self.bad_local_cmd_return = kwargs.get('BAD_LOCAL_CMD_RETURN', None)
        self.bad_remote_cmd_return = kwargs.get('BAD_REMOTE_CMD_RETURN', None)

        self.msg = None
        self.header = "[ERROR]"
        self.show_state = "error"

        self._shell()
        self._remote_shell()
        self._stderr()

        self.log.output(log_message=self.msg, header=self.header, show_state=self.show_state)

    def _stderr(self):
        if self.stderr is not None:
            self.msg = self.stderr.get("stderr")
            self.header = "[ERROR]"
            self.show_state = 'err_nostate'

    def _shell(self):
        if self.bad_local_cmd_return is not None:
            self.msg = self.bad_local_cmd_return.get("cmd")
            self.header = "[SHELL][local]<return_code: {}>".format(self.bad_local_cmd_return.get("return_code"))

    def _remote_shell(self):
        if self.bad_remote_cmd_return is not None:
            self.msg = self.bad_remote_cmd_return.get("cmd")
            self.header = "[SHELL][remote]<return_code: {}>".format(self.bad_remote_cmd_return.get("return_code"))


class LogNormal:
    def __init__(self, **kwargs):
        self.log = Log()

        self.stdout = kwargs.get('STDOUT', None)

        self.template_create_new = kwargs.get('NORM_CREATE_TEMPLATE', None)
        self.local_cmd_return = kwargs.get('NORM_LOCAL_CMD_RETURN', None)
        self.remote_cmd_return = kwargs.get('NORM_REMOTE_CMD_RETURN', None)

        self.msg = None
        self.header = "[NORMAL]"
        self.show_state = "normal"

        self._stdout()
        self._shell()
        self._remote_shell()
        self._template()

        self.log.output(log_message=self.msg, header=self.header, show_state=self.show_state)

    def _stdout(self):
        if self.stdout is not None:
            self.msg = self.stdout.get("stdout")
            self.header = "[STDOUT]"
            self.show_state = ''

    def _shell(self):
        if self.local_cmd_return is not None:
            self.msg = self.local_cmd_return.get("cmd")
            self.header = "[SHELL][local]"

    def _remote_shell(self):
        if self.remote_cmd_return is not None:
            self.msg = self.remote_cmd_return.get("cmd")
            self.header = "[SHELL][remote]"

    def _template(self):
        if self.template_create_new is not None:
            self.msg = self.template_create_new.get("new_file")
            self.header = "[TEMPLATE][create]"
