variable "nomad_cluster_id" {}
variable "remote_state_backend_url" {}
variable "root_password" {}
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

module "rolling_update" {
  source = "../nomad-client"
  nomad_client_ips = data.terraform_remote_state.nomad.outputs.nomad_broker_ssh_ips
  resource = "module.broker.ucloud_instance.nomad_clients"
  root_password = var.root_password
}
