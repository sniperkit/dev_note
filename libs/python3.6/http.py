import urllib
from log import Log


class Http():
    def __init__(self, base_url):
        self.log = Log()

        self.base_url = base_url

    def make_url(self, *uris, **params):
        for uri in uris:
            self.base_url = '{}/{}'.format(self.base_url, uri)

        if params:
            self.base_url = '{}?{}'.format(self.base_url, urllib.urlencode(params))

        return self.base_url

    def download_content(self, dest_file):
        p_url = urllib.FancyURLopener()
        content = p_url.open(self.base_url)

        with open(dest_file, 'w+') as f:
            f.write(content)

        self.log.output(log_message=dest_file, header="[URL][download]", show_state="complete")