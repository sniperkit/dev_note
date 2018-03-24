# from __future__ import print_function

class FontStyle:
    FG_RESET = '\033[0m'
    FG_BOLD = '\033[1m'
    FG_UNDERLINE = '\033[4m'
    FG_STRIKE = '\033[09m'
    FG_INVISIBLE = '\033[08m'
    FG_PINK = '\033[95m'
    FG_BLUE = '\033[94m'
    FG_GREEN = '\033[92m'
    FG_YELLOW = '\033[93m'
    FG_RED = '\033[91m'
    FG_ORANGE ='\033[33m'

    BG_RED ='\033[41m'
    BG_GREEN = '\033[42m'

    def __init__(self):
        pass


class Log():
    def __init__(self):
        self.fg_reset = '\033[0m'

        self.fg_bold = '\033[1m'
        self.fg_underline = '\033[04m'
        self.fg_strike = '\033[09m'

        self.fg_lightgrey = '\033[37m'

        self.fg_orange = '\033[33m'
        self.fg_grey = '\033[90m'
        self.fg_red = '\033[91m'
        self.fg_green = '\033[92m'
        self.fg_yellow = '\033[93m'
        self.fg_blue = '\033[94m'
        self.fg_pink = '\033[95m'

        self.bf_red = '\033[41m'
        self.bf_green = '\033[42m'

    def output(self, log_message, header, show_state='', timestamp=True):
        import datetime

        ts = datetime.datetime.now().strftime("%a, %d %B %Y %I:%M:%S") + ' '
        ts = ts if timestamp is True else ''

        msg_out = ''
        if show_state == 'error': msg_out = " ... " + self.fg_red + 'ERROR' + self.fg_reset
        if show_state == 'warn': msg_out = " ... " + self.fg_orange + 'WARN' + self.fg_reset
        if show_state == 'normal': msg_out = " ... " + self.fg_orange + 'NORMAL' + self.fg_reset
        if show_state == 'complete': msg_out = " ... " + self.fg_green + 'COMPLETE' + self.fg_reset
        if show_state == 'ok': msg_out = " ... " + self.fg_green + 'OK' + self.fg_reset

        if show_state == 'error' or header == '[ERROR]':
            print(self.fg_bold + ts + header + ' ' + log_message + msg_out + self.fg_reset)
        else:
            print(self.fg_lightgrey + ts + header + ' ' + log_message + self.fg_reset + msg_out)


class LogError:
    def __init__(self, **kwargs):
        self.log = Log()
        self.bad_local_cmd_return = kwargs.get('BAD_LOCAL_CMD_RETURN', None)

        self.msg = None
        self.header = "[ERROR]"
        self.show_state = "error"

        self._shell()

        self.log.output(log_message=self.msg, header=self.header, show_state=self.show_state)

    def _shell(self):
        if self.bad_local_cmd_return is not None:
            self.msg = self.bad_local_cmd_return.get("cmd")
            self.header = "[SHELL][local]<return_code: {}>".format(self.bad_local_cmd_return.get("return_code"))


class LogNormal:
    def __init__(self, **kwargs):
        self.log = Log()
        self.norm_local_cmd_return = kwargs.get('NORM_LOCAL_CMD_RETURN', None)

        self.msg = None
        self.header = "[NORMAL]"
        self.show_state = "normal"

        self._shell()

        self.log.output(log_message=self.msg, header=self.header, show_state=self.show_state)

    def _shell(self):
        if self.norm_local_cmd_return is not None:
            self.msg = self.norm_local_cmd_return.get("cmd")
            self.header = "[SHELL][local]"

