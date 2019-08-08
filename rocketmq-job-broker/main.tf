provider "nomad" {
  address = "http://${data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]}:4646"
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
    broker-config     = "http://nomad-jobfile.cn-bj.ufileos.com/broker.conf.tpl"
    brokersvc-name    = local.brokersvc-name
    node-class        = "broker"
    task-limit-per-az = var.allow-multiple-tasks-in-az ? length(local.az) : 1
  }
}

resource "nomad_job" "broker" {
  jobspec = data.template_file.broker-job.rendered
}