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
        self.fg_underline = '\033[4m'
        self.fg_strike = '\033[09m'
        self.fg_pink = '\033[95m'
        self.fg_blue = '\033[94m'
        self.fg_green = '\033[92m'
        self.fg_yellow = '\033[93m'
        self.fg_red = '\033[91m'
        self.fg_orange = '\033[33m'

        self.bf_red = '\033[41m'
        self.bf_green = '\033[42m'

    def output(self, log_message, header, show_state='', timestamp=True):
        import datetime

        ts = datetime.datetime.now().strftime("%a, %d %B %Y %I:%M:%S") + ' '
        ts = ts if timestamp is True else ''

        msg_out = ''
        if show_state == 'error': msg_out = " ... " + self.fg_red + 'ERROR' + self.fg_reset
        if show_state == 'warn': msg_out = " ... " + self.fg_orange + 'WARN' + self.fg_reset
        if show_state == 'complete': msg_out = " ... " + self.fg_green + 'COMPLETE' + self.fg_reset
        if show_state == 'ok': msg_out = " ... " + self.fg_green + 'OK' + self.fg_reset

        print(self.fg_bold + ts + header + self.fg_reset + ' ' + log_message + msg_out)
