module "dcos-mesos-master" {
  role                           = "dcos-mesos-master"
  source                         = "github.com/dcos/tf_dcos_core"
  dcos_install_mode              = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version                   = "${var.dcos_version}"
  bootstrap_private_ip           = "${var.bootstrap_host}"
  dcos_bootstrap_port            = "${var.bootstrap_web_port}"
}

resource "null_resource" "master" {
  count = "${var.master_list}"

  connection {
    type      = "ssh"
    host      = "${var.bootstrap_host}"
    port      = "${var.bootstrap_ssh_port}"
    user      = "${var.bootstrap_username}"
    password  = "${var.bootstrap_password}"
  }

  triggers  {
    bootstrap_private_ip = "${var.bootstrap_host}"
  }

  provisioner "file" {
    source      = "${var.local_dcos_ip_detect_script}"
    destination = "/tmp/ip-detect"
  }

  provisioner "file" {
    content     = "${module.dcos-bootstrap.script}"
    destination = "/tmp/run.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i '/^$/d' ${local.run}",
      "sudo chmod +x ${local.run}",
      "sudo ${local.run}",
    ]
  }
}
