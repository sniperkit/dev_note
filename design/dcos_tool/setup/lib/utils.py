#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-


def split_lines(input_byte, linebreak='\n'):
        lines = []

        for line in input_byte.decode('utf8').split(linebreak):
            lines.append(line.strip())

        return lines
