#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from string import Template
from .log import Log


class UseTemplate():
    def __init__(self, template):
        self.template=template
        self.log=Log()

    def create_new_file(self, file_out, data_dict):
        tpl_content = Template(open(self.template).read())
        new_content = tpl_content.safe_substitute(data_dict)

        with open(file_out, 'w+') as file:
            file.write(new_content)
            self.log.output(log_message=file_out, header='[TEMPLATE][create]', show_state='complete')