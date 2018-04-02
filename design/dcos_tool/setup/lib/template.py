#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from os import makedirs, path
from string import Template

from .log import LogNormal


class UseTemplate():
    def __init__(self, template):
        self.template=template

    def create_new_file(self, new_file, data_dict):
        tpl_content = Template(open(self.template).read())
        new_content = tpl_content.safe_substitute(data_dict)

        makedirs(path.dirname(new_file), exist_ok=True)

        with open(new_file, 'w+') as file:
            file.write(new_content)
            LogNormal(CREATE_TEMPLATE={"new_file": new_file})
