variable "fabio_image" {}
variable "prometheus_image" {}
variable "namesvr_fabio_port" {}
variable "prometheus_port" {}

locals {
  region                  = data.terraform_remote_state.nomad.outputs.region
  nomad_server_access_url = data.terraform_remote_state.nomad.outputs.nomad_server_access_url
  consul_lb_ip            = data.terraform_remote_state.nomad.outputs.consul_lb_ip
}