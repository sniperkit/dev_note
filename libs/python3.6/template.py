from string import Template
from log import Log
from log import LogNormal


class UseTemplate():
    # https://stackoverflow.com/questions/6385686/python-technique-or-simple-templating-system-for-plain-text-output

    def __init__(self, template):
        self.template=template
        self.log=Log()

    def create_new_file(self, new_file, data_dict):
        tpl_content = Template(open(self.template).read())
        new_content = tpl_content.safe_substitute(data_dict)

        with open(new_file, 'w+') as file:
            file.write(new_content)
            LogNormal(NORM_CREATE_TEMPLATE={"new_file": new_file})


tpl=UseTemplate('./test.tpl')
tpl.create_new_file(new_file='./test.out', data_dict={'key': 'value', 'foo': 'bar'})