output "state" {                                                                                                                                                         
  value = "${var.state}"                                                                                                                                                 
}                                                                                                                                                                        
                                                                                                                                                                         
output "dcos_version" {                                                                                                                                                  
  value = "${var.dcos_version}"                                                                                                                                          
}

output "boostrap_host" {                                                                                                                                                 
  value = "${var.bootstrap_host}"                                                                                                                                        
}                                                                                                                                                                        

output "bootstrap_web_port" {
  value = "${var.bootstrap_web_port}"                                                                                                                                    
}

output "mesos_agent_list" {
  value = "${var.mesos_agent_list}"
}

output "num_of_mesos_agent" {
  value = "${var.num_of_mesos_agent}"
}

output "mesos_agent_username" {
  value = "${var.mesos_agent_username}"
}

output "mesos_agent_password" {
  value = "${var.mesos_agent_password}"
}
