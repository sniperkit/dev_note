module "dcos-mesos-agent" {
  role                           = "dcos-mesos-agent"
  source                         = "github.com/dcos/tf_dcos_core"
  dcos_install_mode              = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version                   = "${var.dcos_version}"
  bootstrap_private_ip           = "${var.bootstrap_host}"
  dcos_bootstrap_port            = "${var.bootstrap_web_port}"
}

resource "null_resource" "agent" {
  count = "${var.num_of_mesos_agent}"

  triggers  {
    dcos_agent_list = "\n - ${join("\n - ", var.mesos_agent_list)}"
  }

  connection {
    type      = "ssh"
    host      = "${element(var.mesos_agent_list, count.index)}"
    port      = "22"
    user      = "${var.mesos_agent_username}"
    password  = "${var.mesos_agent_password}"
  }

  provisioner "file" {
    content     = "${module.dcos-mesos-agent.script}"
    destination = "run.sh"
  }

  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${var.bootstrap_host}:${var.bootstrap_web_port}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}
