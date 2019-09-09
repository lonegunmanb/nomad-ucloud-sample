variable "remote_state_backend_url" {}
variable "nomad_cluster_id" {}
locals {
  remote_state = var.nomad_cluster_id == "" ? "rktClusterState" : "rktClusterState-env:${var.nomad_cluster_id}"
}

terraform {
  backend "consul" {
    address = ""
    scheme = "http"
    path = "terraform/fabio"
  }
}

data terraform_remote_state nomad {
  backend = "consul"
  config = {
    address = var.remote_state_backend_url
    scheme = "http"
    path = "terraform/${local.remote_state}"
  }
}