variable "state" {
  type    = "string"
  default = "install"
}

variable "dcos_version" {
  type    = "string"
  default = "1.11.0"
}

variable "bootstrap_host" {
  type    = "string"
  default = ""
}

variable "bootstrap_web_port" {
  type    = "string"
  default = ""
}

variable "mesos_agent_list" {
  type    = "list"
  default = []
}

variable "num_of_mesos_agent" {
  type    = "string"
  default = ""
}

variable "mesos_agent_username" {
  type    = "string"
  default = ""
}

variable "mesos_agent_password" {
  type    = "string"
  default = ""
}