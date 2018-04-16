module "dcos-bootstrap" {
  role                           = "dcos-bootstrap"
  source                         = "github.com/dcos/tf_dcos_core"
  dcos_install_mode              = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version                   = "${var.dcos_version}"
  custom_dcos_download_path      = "${var.custom_dcos_download_path}"
  dcos_cluster_name              = "${var.dcos_cluster_name}"
  bootstrap_private_ip           = "${var.bootstrap_host}"
  dcos_bootstrap_port            = "${var.bootstrap_web_port}"
  dcos_master_list               = "\n - ${join("\n - ", var.mesos_master_list)}"
  dcos_master_discovery          = "${var.mesos_master_discovery}"
  dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
  dcos_resolvers                 = "\n - ${join("\n - ", var.dcos_resolvers)}"
  dcos_ip_detect_public_filename = "${var.dcos_ip_detect_public_filename}"
  dcos_process_timeout           = "${var.dcos_process_timeout}"
  dcos_oauth_enabled             = "${var.dcos_oauth_enabled}"
}

locals {
  run = "/tmp/run.sh"
}

resource "null_resource" "bootstrap" {
  connection {
    type      = "ssh"
    host      = "${var.bootstrap_host}"
    port      = "${var.bootstrap_ssh_port}"
    user      = "${var.bootstrap_username}"
    password  = "${var.bootstrap_password}"
  }

  triggers  {
    bootstrap_private_ip   = "${var.bootstrap_host}"
    dcos_master_discovery  = "${var.mesos_master_discovery}"
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
