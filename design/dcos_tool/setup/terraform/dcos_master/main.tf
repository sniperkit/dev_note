module "dcos-mesos-master" {
  role                           = "dcos-mesos-master"
  source                         = "github.com/dcos/tf_dcos_core"
  dcos_install_mode              = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version                   = "${var.dcos_version}"
  bootstrap_private_ip           = "${var.bootstrap_host}"
  dcos_bootstrap_port            = "${var.bootstrap_web_port}"
}

resource "null_resource" "master" {
  master_count = "${var.num_of_mesos_masters}"

  triggers  {
    current_master_host = "${element(var.mesos_master_list, master_count.index)}"
  }

  connection {
    type      = "ssh"
    host      = "${element(var.mesos_master_list, master_count.index)"
    port      = "22"
    user      = "${var.master_username}"
    password  = "${var.master_password}"
  }

  provisioner "remote-exec" {
    inline = [
      "touch /tmp/123.txt",
    ]
  }
}
