variable "state" {
  type    = "string"
  default = "install"
}

variable "dcos_version" {
  type    = "string"
  default = "1.11.0"
}

variable "custom_dcos_download_path" {
  type    = "string"
  default = ""
}

variable "dcos_cluster_name" {
  type    = "string"
  default = ""
}

variable "bootstrap_host" {
  type    = "string"
  default = ""
}

variable "bootstrap_web_port" {
  type    = "string"
  default = ""
}

variable "mesos_master_list" {
  type    = "list"
  default = []
}

variable "dcos_master_discovery" {
  type    = "string"
  default = "static"
}

variable "dcos_exhibitor_storage_backend" {
  type    = "string"
  default = "static"
}

variable "dcos_resolvers" {
  type    = "list"
  default = [ "8.8.8.8", "8.8.4.4" ]
}

variable "local_dcos_ip_detect_script" {
  type    = "string"
  default = ""
}

variable "dcos_ip_detect_public_filename" {
  type    = "string"
  default = "genconf/ip-detect"
}

variable "dcos_process_timeout" {
  type    = "string"
  default = "10000"
}

variable "dcos_oauth_enabled" {
  type    = "string"
  default = "false"
}