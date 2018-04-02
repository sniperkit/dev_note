#!/usr/bin/python3 -u
# -*- coding: utf-8 -*-
from .template import UseTemplate
from .meta import MetaData
from os.path import splitext


def deploy_marathon_application(configs):
    print(configs)
    mdata = MetaData()

    # tpl = UseTemplate(template=mmarathon.INV_FRONTEND_UI)
    # tpl.create_new_file(
    #     new_file="{0}/{1}".format(mdata.MARATHON_TMP, splitext(mmarathon.INV_FRONTEND_UI)[0]),
    #     data_dict="TODO"
    # )
