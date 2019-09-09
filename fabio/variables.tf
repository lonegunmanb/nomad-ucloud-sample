variable "fabio_image" {}
variable "lb_port" {}

locals {
  region                  = data.terraform_remote_state.nomad.outputs.region
  nomad_server_access_url = data.terraform_remote_state.nomad.outputs.nomad_server_access_url
  consul_lb_ip            = data.terraform_remote_state.nomad.outputs.consul_lb_ip
}