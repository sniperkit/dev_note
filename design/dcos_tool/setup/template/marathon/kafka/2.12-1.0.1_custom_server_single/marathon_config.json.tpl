{
  "id": "/kafka/server",
  "cpus": $CPU,
  "mem": $MEMORY,
  "disk": $DISK,
  "networks": [ { "mode": "container/bridge" } ],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "172.27.11.167:5000/alpine/kafka-2.12-1.0.1/server",
      "forcePullImage": true
    },
    "portMappings": [
      { "containerPort": 9092, "hostPort": 0 }
    ]
  }
}