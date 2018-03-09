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


def log(log_message, header, log_state='', get_timestamp=True):
    import datetime

    ts = datetime.datetime.now().strftime("%a, %d %B %Y %I:%M:%S") + ' '
    ts = ts if get_timestamp is True else ''

    state_msg = ''
    if log_state == 'error': state_msg = "..." + FontStyle.FG_RED + "ERROR" + FontStyle.FG_RESET
    if log_state == 'warn': state_msg = "..." + FontStyle.FG_ORANGE + "WARN" + FontStyle.FG_RESET
    if log_state == 'ok': state_msg = "..." + FontStyle.FG_GREEN + "OK" + FontStyle.FG_RESET

    print(FontStyle.FG_BOLD + ts + header + FontStyle.FG_RESET + ' ' + log_message + state_msg)
