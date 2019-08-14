variable rocketmq_docker_image {
  default = "uhub.service.ucloud.cn/lonegunmanb/rocketmq"
}
variable rocketmq_version {
  default = "4.5.1"
}
variable terraform-image {
  default = "uhub.service.ucloud.cn/lonegunmanb/terraform:0.11.14"
}
variable ucloud_pubkey {}
variable ucloud_secret {}
variable nomad_cluster_id {}
variable remote_state_backend_url {
  default = "http://localhost:8500"
}

variable allow_multiple_tasks_in_az {}