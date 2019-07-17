variable "rocketmq_docker_image" {}
variable "rocketmq_version" {}
variable "namesvc_name" {}
variable "brokersvc_name" {}

data "terraform_remote_state" "nomad" {
  backend = "local"
  config = {
    path = "${path.module}/../../terraform.tfstate"
  }
}

locals {
  az = "${data.terraform_remote_state.nomad.az}"
  cluster-id = "${data.terraform_remote_state.nomad.cluster_id}"
  broker-job-hcl = "${path.module}/broker-job.hcl"
  console-job-hcl = "${path.module}/console-job.hcl"
}

provider "nomad" {
  address = "http://${data.terraform_remote_state.nomad.nomad_servers_ips[0]}:4646"
  region  = "cn-bj2"
}
data "template_file" "broker-job" {
  count = "${length(local.az)}"
  template = "${file(local.broker-job-hcl)}"
  vars = {
    job-name = "broker-${local.cluster-id}-${count.index}"
    cmd = "./mqbroker"
    cluster-id = "${local.cluster-id}"
    az = "${local.az[count.index]}"
    index = "${count.index}"
    broker-image = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    console-image = "uhub.service.ucloud.cn/lonegunmanb/rocketmq-console-ng:latest"
    rockermq-version = "${var.rocketmq_version}"
    broker-config = "http://nomad-jobfile.cn-bj.ufileos.com/broker.conf.tpl"
    namesvc-name = "${var.namesvc_name}"
    brokersvc-name = "${var.brokersvc_name}"
    node-class = "broker"
  }
}

resource "nomad_job" "broker" {
  count = "${length(local.az)}"
  jobspec = "${data.template_file.broker-job.*.rendered[count.index]}"
}