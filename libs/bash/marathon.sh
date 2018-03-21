# https://docs.mesosphere.com/pdf/1.10/deploying-services/marathon-api/1.10-deploying-services-marathon-api.pdf

. ./curl.sh

function marathon_deploy_app {
  # single container
  local _host=$1
  local _json=$2

  curl_request "curl -X POST http://${_host}/v2/apps -d @${_json} -H 'Content-type: application/json'"
}

function marathon_deploy_pods {
  # multi-container on same node with shared resource
  local _host=$1
  local _json=$2

  curl -X POST http://${_host}/v2/pods -d @${_json} -H "Content-type: application/json"
}

function marathon_get_pods {
  local _host=$1
  local _pod=$2

  curl -X GET http://${_host}/v2/pods/${_pod}::status
}

function marathon_delete_pods {
  local _host=$1
  local _pod=$2

  curl -X DELETE http://${_host}/v2/pods/${_pod}
}

function marathon_get_logging {
  local _host=$1

  curl -X GET http://${_host}/logging| python -mjson.tool
}

 curl -X POST http://192.168.201.102:8080/logging -d "DEBUG"

marathon_deploy_app "192.168.201.108:8080" "/tmp/marathon/sample.json"