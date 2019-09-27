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
  nomad_server_ips = data.terraform_remote_state.nomad.outputs.nomad_server_ssh_ips
  az = data.terraform_remote_state.nomad.outputs.az
  module = "module.nomad_servers"
}
locals {
  target = {for i, ip in local.nomad_server_ips: i => ip if i % length(local.az) == var.mod}
}

resource "null_resource" "update" {
  for_each = local.target
  triggers = {
    trigger = uuid()
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform taint ${local.module}.ucloud_instance.nomad_servers[${each.key}]"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform taint ${local.module}.null_resource.setup[${each.key}]"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform taint ${local.module}.ucloud_eip.nomad_servers[${each.key}]"
    on_failure = "continue"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform apply --auto-approve -target=${local.module}.ucloud_instance.nomad_servers[${each.key}] -target=${local.module}.null_resource.setup[${each.key}] -target=${local.module}.ucloud_eip.nomad_servers[${each.key}] -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform apply --auto-approve -target=${local.module}.ucloud_instance.nomad_servers[${each.key}] -target=${local.module}.null_resource.setup[${each.key}] -target=${local.module}.ucloud_eip.nomad_servers[${each.key}] -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
}
