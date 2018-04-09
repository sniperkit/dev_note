---
bootstrap_url: http://$BOOTSTRAP_HOST:$BOOTSTRAP_PORT
cluster_name: $CLUSTER_NAME
exhibitor_storage_backend: static
master_discovery: static
ip_detect_public_filename: genconf/ip-detect
master_list:
- $MASTER_HOSTS
resolvers:
- 8.8.8.8
- 8.8.4.4
process_timeout: 10000
oauth_enabled: 'false'
mesos_agent_work_dir: /opt/tmp_mesos
...