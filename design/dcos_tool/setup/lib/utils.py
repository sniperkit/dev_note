#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-


def split_lines(input_byte, linebreak='\n'):
    lines = []

    for line in input_byte.decode('utf8').split(linebreak):
        lines.append(line.strip())

    return lines


def remove_ansi_escape(line, clear=False):
    import re

    escapes = ['\x9B', '\x1B[']
    if clear and any(escape in line for escape in escapes):
        return ''

    ansi_regex = r'(\x9B|\x1B\[)[0-?]*[ -/]*[@-~]'
    ansi_escape = re.compile(ansi_regex, flags=re.IGNORECASE)
    return ansi_escape.sub('', line)


def is_empty_string(input):
    return bool(not input or len(input.strip()) == 0)
