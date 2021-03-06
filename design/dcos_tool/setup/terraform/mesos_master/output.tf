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

output "mesos_master_list" {
  value = "${var.mesos_master_list}"
}

output "num_of_mesos_master" {
  value = "${var.num_of_mesos_master}"
}

output "mesos_master_username" {
  value = "${var.mesos_master_username}"
}

output "mesos_master_password" {
  value = "${var.mesos_master_password}"
}
