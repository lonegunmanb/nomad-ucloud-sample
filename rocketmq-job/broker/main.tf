variable rocketmq_docker_image {}
variable rocketmq_version {}
variable namesvc_name {}
variable brokersvc_name {}
variable allow-multiple-tasks-in-az {}

data "terraform_remote_state" "nomad" {
  backend = "local"
  config = {
    path = "${path.module}/../../terraform.tfstate"
  }
}

locals {
  az              = data.terraform_remote_state.nomad.outputs.az
  region          = data.terraform_remote_state.nomad.outputs.region
  cluster-id      = data.terraform_remote_state.nomad.outputs.cluster_id
  broker-job-hcl  = "${path.module}/broker-job.hcl"
  console-job-hcl = "${path.module}/console-job.hcl"
}

provider "nomad" {
  address = "http://${data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]}:4646"
  region  = local.region
}

data "template_file" "broker-job" {
  template = file(local.broker-job-hcl)
  vars = {
    job-name          = "broker-${local.cluster-id}"
    cmd               = "./mqbroker"
    cluster-id        = local.cluster-id
    region            = local.region
    count             = length(local.az)
    min-az-count      = length(distinct(local.az))
    broker-image      = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    console-image     = "uhub.service.ucloud.cn/lonegunmanb/rocketmq-console-ng:latest"
    rockermq-version  = var.rocketmq_version
    broker-config     = "http://nomad-jobfile.cn-bj.ufileos.com/broker.conf.tpl"
    namesvc-name      = var.namesvc_name
    brokersvc-name    = var.brokersvc_name
    node-class        = "broker"
    task-limit-per-az = var.allow-multiple-tasks-in-az ? length(local.az) : 1
  }
}

resource "nomad_job" "broker" {
  jobspec = data.template_file.broker-job.rendered
}

