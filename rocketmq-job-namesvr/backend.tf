terraform {
  backend "consul" {
    address = ""
    scheme = "http"
    path = ""
  }
}

data terraform_remote_state nomad {
  backend = "consul"
  config = {
    address = ""
    scheme = "http"
    path = "terraform/rktClusterState"
  }
}