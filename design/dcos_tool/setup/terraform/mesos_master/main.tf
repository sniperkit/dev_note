module "dcos-mesos-master" {
  role                           = "dcos-mesos-master"
  source                         = "github.com/dcos/tf_dcos_core"
  dcos_install_mode              = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version                   = "${var.dcos_version}"
  bootstrap_private_ip           = "${var.bootstrap_host}"
  dcos_bootstrap_port            = "${var.bootstrap_web_port}"
}

resource "null_resource" "master" {
  count = "${var.num_of_mesos_master}"

  triggers  {
    current_master_host = "var.mesos_master_list[count.index]"
  }

  connection {
    type      = "ssh"
    host      = "var.mesos_master_list[count.index]"
    port      = "22"
    user      = "${var.mesos_master_username}"
    password  = "${var.mesos_master_password}"
  }

  provisioner "remote-exec" {
    inline = [
      "touch /tmp/123.txt",
    ]
  }
}
