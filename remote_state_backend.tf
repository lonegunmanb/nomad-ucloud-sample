data terraform_remote_state network {
  backend = "consul"
  config = {
    address = ""
    scheme = "http"
    path = "terraform/network_state"
  }
}