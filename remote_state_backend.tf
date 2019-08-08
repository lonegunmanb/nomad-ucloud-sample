locals {
  path = terraform.workspace == "default" ? "network_state" : "network_state-env:${terraform.workspace}"
}
data terraform_remote_state network {
  backend = "consul"
  config = {
    address = ""
    scheme = "http"
    path = "terraform/${local.path}"
  }
}