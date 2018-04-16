#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
import os

from .meta import MetaData
from .connect import Shell
from .log import LogError


class Deploy:
    def __init__(self, configs, verb):
        self.configs = configs
        self.verb = verb
        self.meta = MetaData()

    def with_marathon(self):
        _configs = []

        for application in self.configs.get("applications"):

            _data_dict = {}
            for key in application:
                _data_dict.update({key.upper(): '{0}'.format(application.get(key))})

            _file = "{0}/{1}/{2}/marathon_config.json".format(
                self.meta.MARATHON_TEMPLATE_DIR,
                application.get("name"),
                application.get("version")
            )
            _configs.append(_file)

        for _config in _configs:
            if os.path.isfile(_config):
                _cmd = "curl -X POST http://{0}:8080/v2/apps -d @{1} -H 'Content-type: application/json'".format(
                    self.configs.get('master_nodes').get('address')[0],_config)
                _session = Shell(verb=self.verb)
                _session.local(_cmd, info="deploy marathon application")
            else:
                LogError(verbosity=self.verb, INFO={"message": "{0} exist".format(_config)})
