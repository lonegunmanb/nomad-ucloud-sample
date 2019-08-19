locals {
  nomad_server_ip = length(data.terraform_remote_state.nomad.outputs.nomad_server_ip) > 15 ? "[${data.terraform_remote_state.nomad.outputs.nomad_server_ip}]":data.terraform_remote_state.nomad.outputs.nomad_server_ip
}

provider "nomad" {
  address = "http://${local.nomad_server_ip}:4646"
  region  = local.region
}

data "template_file" "broker-job" {
  template = file(local.broker-job-hcl)
  vars = {
    job-name          = "broker-${local.broker_clusterId}"
    cmd               = "./mqbroker"
    cluster-id        = local.broker_clusterId
    namesvr_clusterId = var.namesvr_clusterId
    region            = local.region
    count             = length(local.az)
    broker-image      = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    rockermq-version  = var.rocketmq_version
    brokersvc-name    = local.brokersvc-name
    node-class        = "broker"
    task-limit-per-az = var.allow_multiple_tasks_in_az ? length(local.az) : 1
  }
}

resource "nomad_job" "broker" {
  jobspec = data.template_file.broker-job.rendered
}