#!/usr/bin/env python36
# -*- coding: utf-8 -*-

import os
import argparse


def cli_menu_parser_0():
    parser = argparse.ArgumentParser(description='GE tool for environment provision and application deployment')

    parser.add_argument('-a', '--action',
                        choices=['prepare', 'provision', 'deploy', 'destroy'],
                        help='run action',
                        required=True)

    parser.add_argument('-p', '--prepare',
                        choices=['bootstrap', 'application'],
                        help='prepare requirements',
                        required=('-a' or '--action') and 'prepare' in os.sys.argv)

    parser.add_argument('-P', '--platform',
                        choices=['aws', 'any'],
                        help='set platform',
                        required=('-a' or '--action') and
                                 ('prepare' or 'provision' or 'destroy') in os.sys.argv,
                        default='any')

    parser.add_argument('-n', '--node',
                        choices=['bootstrap', 'master', 'agent'],
                        help='set node purpose',
                        required=('-a' or '--action') and
                                 'provision' in os.sys.argv and
                                 'any' in os.sys.argv)

    parser.add_argument('-c', '--config',
                        help='give config file path',
                        required=True)

    parser.add_argument('-v', '--verbosity',
                        action="count",
                        help="increase output verbosity",
                        default=1)

    parser.add_argument('--version',
                        action='version',
                        version='%(prog)s 1.0.0-alpha')

    args = parser.parse_args()

    return args


if __name__ == "__main__":

    args = cli_menu_parser_0()
