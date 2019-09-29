variable "root_password" {}
variable "mod" {
  type = number
}
variable "remote_state_backend_url" {}
variable "nomad_cluster_id" {}

locals {
  remote_state = var.nomad_cluster_id == "" ? "rktClusterState" : "rktClusterState-env:${var.nomad_cluster_id}"
}
data terraform_remote_state nomad {
  backend = "consul"
  config = {
    address = var.remote_state_backend_url
    scheme = "http"
    path = "terraform/${local.remote_state}"
  }
}
locals {
  nomad_server_ips = data.terraform_remote_state.nomad.outputs.nomad_server_ssh_ip_array
  az = data.terraform_remote_state.nomad.outputs.az
  module = "module.nomad_servers"
}

locals {
  path = "${path.module}/../../"
}

resource "null_resource" "update" {
  for_each = toset(local.nomad_server_ips[var.mod])
  triggers = {
    trigger = uuid()
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "sh taint_module.sh nomad_server${var.mod}"
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform apply --auto-approve -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
}
