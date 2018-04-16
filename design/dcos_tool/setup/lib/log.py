#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-


class Log:
    def __init__(self):
        self.fg_none = '\033[0m'
        self.fg_bold = '\033[1m'
        self.fg_lightgrey = '\033[37m'
        self.fg_red = '\033[91m'
        self.fg_green = '\033[92m'
        self.fg_yellow = '\033[93m'

        self.fg_set = self.fg_none
        self.fg_clear = self.fg_none

    def output(self, message, header, show_state=None, timestamp=True):
        import datetime

        ts = datetime.datetime.now().strftime("%a, %d %B %Y %I:%M:%S") + ' '
        ts = ts if timestamp is True else ''

        state = ''
        if show_state == 'error': state = " ... " + self.fg_red + 'ERROR' + self.fg_none
        if show_state == 'warn' : state = " ... " + self.fg_yellow + 'WARN' + self.fg_none
        if show_state == 'pass': state = " ... " + self.fg_green + 'PASS' + self.fg_none
        if show_state == 'error' or state == '[ERROR]': self.fg_set = self.fg_bold

        print(self.fg_set + ts + header + ' ' + message + state + self.fg_clear)


class LogError:
    def __init__(self, verbosity, **kwargs):
        self.logs = []
        self.verbosity = verbosity

        self.info = kwargs.get('INFO', None)
        self.stderr = kwargs.get('STDERR', None)
        self.ssh_connect = kwargs.get('SSH_CONNECT', None)
        self.local_cmd_return = kwargs.get('LOCAL_CMD_RETURN', None)
        self.remote_cmd_return = kwargs.get('REMOTE_CMD_RETURN', None)

        self.message = ''
        self.header = "[ERROR]"
        self.state = "error"

        if int(verbosity) >= 1:
            if self._info(): self.logs.append(self._info())

        if int(verbosity) >= 2:
            if self._stderr(): self.logs.append(self._stderr())
            if self._shell(): self.logs.append(self._shell())

        for log in self.logs:
            Log().output(
                message=log.get("message"),
                header=log.get("header"),
                show_state=log.get("state")
            )

    def _info(self):
        if self.info is not None:
            return dict(
                header="[INFO]",
                message=self.info.get("message"),
                state=self.state
            )

    def _stderr(self):
        if self.stderr is not None:
            return dict(
                header="[ERROR]",
                message=self.stderr.get("stderr"),
                state=None
            )

    def _session(self):
        if self.ssh_connect is not None:
            return dict(
                header="[SESSION][ssh][connect]",
                state = None
            )

    def _shell(self):
        if self.local_cmd_return is not None:
            return dict(
                header="[SHELL][local]<return_code: {}>".format(self.local_cmd_return.get("return_code")),
                message=self.local_cmd_return.get("cmd"),
                state=None
            )

        if self.remote_cmd_return is not None:
            return dict(
                header="[SHELL][remote]<return_code: {}>".format(self.remote_cmd_return.get("return_code")),
                message=self.remote_cmd_return.get("cmd"),
                state=None
            )


class LogWarn:
    def __init__(self, verb, **kwargs):
        self.logs = []
        self.verbosity = verb

        self.info = kwargs.get('INFO', None)

        self.message = ''
        self.header = "[WARN]"
        self.state = "warn"

        if int(verb) >= 1:
            if self._info(): self.logs.append(self._info())

        if int(verb) >= 2:
            pass

        for log in self.logs:
            Log().output(
                message=log.get("message"),
                header=log.get("header"),
                show_state=log.get("state")
            )

    def _info(self):
        if self.info is not None:
            return dict(
                header="[INFO]",
                message=self.info.get("message"),
                state=self.state
            )


class LogNormal:
    def __init__(self, verb, **kwargs):
        self.logs = []
        self.do_log = False

        self.info = kwargs.get('INFO', None)
        self.stdout = kwargs.get('STDOUT', None)
        self.ssh_connect = kwargs.get('SSH_CONNECT', None)
        self.template_create_new = kwargs.get('CREATE_TEMPLATE', None)
        self.local_cmd_return = kwargs.get('LOCAL_CMD_RETURN', None)
        self.remote_cmd_return = kwargs.get('REMOTE_CMD_RETURN', None)

        self.message = ''
        self.header = "[-]"
        self.state = "pass"

        if int(verb) >= 1:
            if self._info(): self.logs.append(self._info())

        if int(verb) >= 2:
            if self._stdout(): self.logs.append(self._stdout())
            if self._session(): self.logs.append(self._session())
            if self._shell(): self.logs.append(self._shell())
            if self._template(): self.logs.append(self._template())

        for log in self.logs:
            Log().output(
                message=log.get("message"),
                header=log.get("header"),
                show_state=log.get("state")
            )

    def _info(self):
        if self.info is not None:
            return dict(
                header="[INFO]",
                message=self.info.get("message"),
                state=self.state
            )

    def _stdout(self):
        if self.stdout is not None:
            return dict(
                header="[STDOUT]",
                message=self.stdout.get("stdout"),
                state=None
            )

    def _session(self):
        if self.ssh_connect is not None:
            return dict(
                header="[SESSION][ssh]",
                message="connect",
                state=None
            )

    def _shell(self):
        if self.local_cmd_return is not None:
            return dict(
                header="[SHELL][local]",
                message=self.local_cmd_return.get("cmd"),
                state=None
            )

        if self.remote_cmd_return is not None:
            return dict(
                header="[SHELL][remote]",
                message=self.remote_cmd_return.get("cmd"),
                state=None
            )

    def _template(self):
        if self.template_create_new is not None:
            return dict(
                header="[TEMPLATE][create]",
                message=self.template_create_new.get("new_file"),
                state=None
            )
