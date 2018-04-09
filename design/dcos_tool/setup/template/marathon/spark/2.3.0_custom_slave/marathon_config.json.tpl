{
  "id": "/spark/slave",
  "cpus": $CPU,
  "mem": $MEMORY,
  "disk": $DISK,
  "networks": [ { "mode": "container/bridge" } ],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "172.27.11.167:5000/alpine/spark-2.3.0"
    },
    "portMappings": [
      { "containerPort": 8080, "hostPort": 0 },
      { "containerPort": 7077, "hostPort": 0 },
      { "containerPort": 6066, "hostPort": 0 },
      { "containerPort": 4040, "hostPort": 0 }
    ]
  },
  "cmd": "./sbin/start-slave.sh spark://spark-master.marathon.l4lb.thisdcos.directory:7077 && spark-shell"
}