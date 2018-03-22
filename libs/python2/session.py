import paramiko
import time
from log import Log


class SshSession():
    def __init__(self, dest_host, dest_user, dest_password):
        self.host=str(dest_host)
        self.username=str(dest_user)
        self.password=str(dest_password)
        self.log=Log()

    def login_with_password(self):
        p_ssh = paramiko.SSHClient()
        p_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            p_ssh.connect(hostname=self.host, username=self.username, password=self.password)
            self.log.output(log_message='connect', header='[SESSION][ssh]', show_state='ok')

            return p_ssh

        except (paramiko.ssh_exception.SSHException, paramiko.ssh_exception.NoValidConnectionsError) as e:
            self.log.output(log_message='connect', header='[SESSION][ssh]', show_state='error')
            self.log.output(log_message=str(e), header='[SESSION][error]')

            return None


class Shell():
    def __init__(self, session):
        self.session = session.invoke_shell()

        self.retry_expire = int('60')
        self.retry_interval = int('1')

        self.linebreak = str('\n')

    def input(self, input):
        self.session.send(input + self.linebreak)

    def response_byte(self):
        timeout = round(time.time()) + self.retry_expire

        while time.time() < timeout:
            time.sleep(self.retry_interval)

            if self.session.recv_ready():
                return self.session.recv(1024)

    def response_lines(self):
        lines = []

        for line in self.response_byte().decode('utf8').split(self.linebreak):
            lines.append(line.strip())

        return lines
