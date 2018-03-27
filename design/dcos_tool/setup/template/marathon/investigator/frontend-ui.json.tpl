{
  "id": "/investigator/frontend-ui",
  "cpus": $CPU,
  "mem": $MEMORY,
  "disk": $STORAGE,
  "networks": [ { "mode": "container/bridge" } ],
  "constraints": [["hostname", "LIKE", "investigator_frontend"]],
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "quay.io/geminidata/frontend_ui:develop_latest"
    },
    "portMappings": [
      { "containerPort": 8013, "hostPort": 28013 },
      { "containerPort": 8010, "hostPort": 28010 }
    ]
  },
  "env": {
    "REST_API_PORT": "28010", //frontend_host
    "WEBSOCKET_PORT": "8080",
    "STATIC_FILES_SERVER_PORT": "8013",
    "GOOGLE_CLIENT_ID": "674466874630-e71bv5kts72cgrkg5t2d9k7ig62elm95.apps.googleusercontent.com",
    "GOOGLE_SECRET": "VJ7VYRuWQ90TnSyvTl3pwG_F",
    "LINKEDIN_CLIENT_ID": "77boe6rm2mgidd",
    "LINKEDIN_SECRET": "z37r0dB1UcRQX40S",
    "LOG_LEVEL": "info",
    "SENTRY_DSN": ""
  },
  "fetch" : [
    {
      "uri" : "http://leader.mesos:10080/bootstrap/docker.tar.gz",
      "extract" : true
    }
  ]
}