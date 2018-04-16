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
    dcos_master_list = "\n - ${join("\n - ", var.mesos_master_list)}"
  }

  connection {
    type      = "ssh"
    host      = "${element(var.mesos_master_list, count.index)}"
    port      = "22"
    user      = "${var.mesos_master_username}"
    password  = "${var.mesos_master_password}"
  }

  provisioner "file" {
    content     = "${module.dcos-mesos-master.script}"
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

  provisioner "remote-exec" {
    inline = [
      "until $(curl --output /dev/null --silent --head --fail http://${element(var.mesos_master_list, count.index)}/); do printf 'loading DC/OS...'; sleep 10; done"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "touch /tmp/123.txt",
    ]
  }
}
