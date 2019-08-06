terraform {
  backend "consul" {
    address = ""
    scheme = "http"
    path = "terraform/network_state"
  }
}