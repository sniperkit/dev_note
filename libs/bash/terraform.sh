# https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

function tf_set_log {
  export TF_LOG=INFO
}

function tf_build_plugin {
  local type=${1:-provider}
  local name=$2

  go build -o terraform-${type}-${name} -v
}

function tf_init {
  terraform init
}

function tf_apply {
  local _var=$1

  terraform apply -var-file=${_var}
}

function tf_destroy {
  terraform destroy
}