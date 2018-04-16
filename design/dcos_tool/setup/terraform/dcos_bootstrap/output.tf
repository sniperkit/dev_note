output "state" {                                                                                                                                                         
  value = "${var.state}"                                                                                                                                                 
}                                                                                                                                                                        
                                                                                                                                                                         
output "dcos_version" {                                                                                                                                                  
  value = "${var.dcos_version}"                                                                                                                                          
}

output "custom_dcos_download_path" {
  value = "${var.custom_dcos_download_path}"
}

output "dcos_cluster_name" {
  value = "${var.dcos_cluster_name}"
}
                                                                                                                                                                         
output "boostrap_host" {                                                                                                                                                 
  value = "${var.bootstrap_host}"                                                                                                                                        
}                                                                                                                                                                        
                                                                                                                                                                         
output "bootstrap_ssh_port" {                                                                                                                                            
  value = "${var.bootstrap_ssh_port}"                                                                                                                                    
}                                                                                                                                                                        

output "bootstrap_web_port" {
  value = "${var.bootstrap_web_port}"                                                                                                                                    
}                                                                                                                                                                        
                                                                                                                                                                         
output "bootstrap_username" {
  value = "${var.bootstrap_username}"
}                                                                                                                                                                        
                                                                                                                                                                         
output "bootstrap_password" {                                                                                                                                            
  value = "${var.bootstrap_password}"                                                                                                                                    
}

output "mesos_master_list" {
  value = "${var.dcos_master_list}"
}

output "dcos_exhibitor_storage_backend" {
  value = "${var.dcos_exhibitor_storage_backend}"
}

output "dcos_resolvers" {
  value = "${var.dcos_resolvers}"
}

output "local_dcos_ip_detect_script" {
  value = "${var.local_dcos_ip_detect_script}"
}

output "dcos_ip_detect_public_filename" {
  value = "${var.dcos_ip_detect_public_filename}"
}

output "dcos_process_timeout" {
  value = "${var.dcos_process_timeout}"
}

output "dcos_oauth_enabled" {
  value = "${var.dcos_oauth_enabled}"
}