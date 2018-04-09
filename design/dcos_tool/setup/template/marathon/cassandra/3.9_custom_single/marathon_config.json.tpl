{
  "id": "/cassandra/single",
  "cpus": $CPU,
  "mem": $MEMORY,
  "disk": $DISK,
  "networks": [ { "mode": "container/bridge" } ],
  "container": {
    "type": "MESOS",
    "docker": {
      "image": "172.27.11.167:5000/alpine/cassandra-3.9/single",
      "forcePullImage": true
    },
    "portMappings": [
      { "containerPort": 9160, "hostPort": 0, "labels": { "VIP_0": "cassandra-single:9160" } },
      { "containerPort": 9042, "hostPort": 0 },
      { "containerPort": 7000, "hostPort": 0 },
      { "containerPort": 7001, "hostPort": 0 },
      { "containerPort": 7199, "hostPort": 0 }
    ]
  }
}
