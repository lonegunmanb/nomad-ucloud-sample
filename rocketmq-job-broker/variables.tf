locals {
  namesvc-name = "namesvc-service-${var.namesvr_clusterId}"
  broker_clusterId = terraform.workspace
  brokersvc-name = "brokersvc-service-${local.broker_clusterId}"
  broker-job-hcl  = "${path.module}/broker-job.hcl.tplt"
  az = data.terraform_remote_state.nomad.outputs.az
  region = data.terraform_remote_state.nomad.outputs.region
  projectId = data.terraform_remote_state.nomad.outputs.projectId
  consul_access_ip = data.terraform_remote_state.nomad.outputs.consul_access_ip
  consul_access_url = length(local.consul_access_ip) > 15 ? "http://[${local.consul_access_ip}]:8500" : "http://${local.consul_access_ip}:8500"
  vpc_id = data.terraform_remote_state.nomad.outputs.clientVpcId
  subnet_id = data.terraform_remote_state.nomad.outputs.clientSubnetId
}
variable rocketmq_docker_image {}
variable rocketmq_version {}
variable allow_multiple_tasks_in_az {}
variable namesvr_clusterId {}
variable nomad_cluster_id {}
variable remote_state_backend_url {}

variable ucloud_pubkey {}
variable ucloud_secret {}
variable ucloud_api_base_url {}
variable terraform-image {}
variable broker_size {
  type = number
  default = 1
}
locals {
  base_bandwidth = 50
  base_cpu       = 2000
  base_memory    = 4096
}