locals {
  backend_path = terraform.workspace == "default" ? "network_state" : "network_state-env:${terraform.workspace}"
}

data terraform_remote_state network {
  backend = "consul"
  config = {
    address = var.remote_state_backend_url
    scheme = "http"
    path = "terraform/${local.backend_path}"
  }
}