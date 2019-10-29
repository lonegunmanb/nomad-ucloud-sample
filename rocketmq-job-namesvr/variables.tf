variable rocketmq_docker_image {
  default = "uhub.service.ucloud.cn/lonegunmanb/rocketmq"
}
variable rocketmq_version {
  default = "4.5.1"
}
variable terraform-image {
  default = "uhub.service.ucloud.cn/lonegunmanb/terraform:0.12.10"
}
variable "golang-image" {
  default = "uhub.service.ucloud.cn/lonegunmanb/golang:alpine"
}
variable ucloud_pubkey {}
variable ucloud_secret {}
variable ucloud_api_base_url {}
variable nomad_cluster_id {}
variable remote_state_backend_url {}

variable allow_multiple_tasks_in_az {}
variable internal_use {
  type = bool
}
locals {
  consul_access_ip  = data.terraform_remote_state.nomad.outputs.consul_access_ip
  consul_access_url = length(local.consul_access_ip) > 15 ? "http://[${local.consul_access_ip}]:8500" : "http://${local.consul_access_ip}:8500"
}
