terraform {
  backend "consul" {
    address = ""
    scheme = "http"
    path = "terraform/namesvr"
  }
}

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