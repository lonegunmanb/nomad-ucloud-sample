terraform {
  backend "consul" {
    address = ""
    scheme = "http"
    path = "terraform/namesvr"
  }
}
