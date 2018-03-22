#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-


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
