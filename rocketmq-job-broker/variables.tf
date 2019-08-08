locals {
  namesvc-name = "namesvc-service-${var.clusterId}"
  brokersvc-name = "brokersvc-service-${var.clusterId}"
  broker-job-hcl  = "${path.module}/broker-job.hcl"
  console-job-hcl = "${path.module}/console-job.hcl"
  az = data.terraform_remote_state.nomad.outputs.az
  region = data.terraform_remote_state.nomad.outputs.region
}
variable rocketmq_docker_image {}
variable rocketmq_version {}
variable allow-multiple-tasks-in-az {}
variable clusterId {}
variable nomad_cluster_id {
  default = ""
}