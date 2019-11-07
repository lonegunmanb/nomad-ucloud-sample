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
  consul_access_url = var.consul_access_url
}

variable "namesvr_cpu" {
  default = 1000
}
variable "namesvr_memory" {
  default = 2048
}
variable "az" {}
variable "region" {}
variable "project_id" {}
variable "nomad_server_address" {}
variable "vpcId" {}
variable "subnetId" {}
variable "consul_access_url" {}
