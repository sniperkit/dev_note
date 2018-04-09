{
  "id": "/kafka/zookeeper",
  "cpus": $CPU,
  "mem": $MEMORY,
  "disk": $DISK,
  "networks": [ { "mode": "container/bridge" } ],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "172.27.11.167:5000/alpine/kafka-2.12-1.0.1/zookeeper",
      "forcePullImage": true
    },
    "portMappings": [
      { "containerPort": 2181, "hostPort": 0 , "labels": { "VIP_0": "kafka-zookeeper:2181" } }
    ]
  }
}