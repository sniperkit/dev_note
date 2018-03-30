#                                                                               
# The Alluxio Open Foundation licenses this work under the Apache License, versi
# (the "License"). You may not use this work except in compliance with the Licen
# available at www.apache.org/licenses/LICENSE-2.0                              
#                                                                               
# This software is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDIT
# either express or implied, as more fully set forth in the License.            
#                                                                               
# See the NOTICE file distributed with this work for information regarding copyr
#                                                                               
                                                                                
# Site specific configuration properties for Alluxio                            
# Details about all configuration properties http://www.alluxio.org/documentatio
                                                                                
# Common properties                                                             
alluxio.master.hostname=localhost
alluxio.underfs.address=/tmp
                                                                                
# Security properties                                                           
# alluxio.security.authorization.permission.enabled=true                        
# alluxio.security.authentication.type=SIMPLE                                   
                                                                                
# Worker properties                                                             
# alluxio.worker.memory.size=1GB                                                
# alluxio.worker.tieredstore.levels=1                                           
alluxio.worker.tieredstore.level0.alias=MEM
#alluxio.worker.tieredstore.level0.dirs.path=/mnt/ramdisk
alluxio.worker.tieredstore.level0.dirs.path=/dev/shm
                                                                                
# User properties                                                               
# alluxio.user.file.readtype.default=CACHE_PROMOTE                              
# alluxio.user.file.writetype.default=MUST_CACHE        