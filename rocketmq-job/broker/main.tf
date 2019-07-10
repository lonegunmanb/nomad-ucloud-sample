variable "rocketmq_version" {}
variable "rocketmq_docker_image" {}

data "terraform_remote_state" "nomad" {
  backend = "local"
  config = {
    path = "${path.module}/../../terraform.tfstate"
  }
}

locals {
  az = "${data.terraform_remote_state.nomad.az}"
  cluster-id = "${data.terraform_remote_state.nomad.cluster_id}"
}

provider "nomad" {
  address = "http://${data.terraform_remote_state.nomad.nomad_servers_ips[0]}:4646"
  region  = "cn-bj2"
}

locals {
  namesvr-sidecar-hcl = "${path.module}/namesvr-sidecar.hcl"
  dledger-sidecar-hcl = "${path.module}/dledger-sidecar.hcl"
  broker-job-hcl = "${path.module}/broker-job.hcl"
}

data "template_file" "namesvr-sidecar" {
  count = "${length(local.az)}"
  template = "${file(local.namesvr-sidecar-hcl)}"
  vars = {
    index = "${count.index}"
    cluster-id = "${local.cluster-id}"
  }
}

data "template_file" "dledger-sidecar" {
  count = "${length(local.az)}"
  template = "${file(local.dledger-sidecar-hcl)}"
  vars = {
    index = "${count.index}"
    cluster-id = "${local.cluster-id}"
  }
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
    rockermq-version = "${var.rocketmq_version}"
    broker-config = "http://nomad-jobfile.cn-bj.ufileos.com/broker.conf.tpl"
    task-namesvr-sidecar0 = "${data.template_file.namesvr-sidecar.*.rendered[0]}"
    task-namesvr-sidecar1 = "${data.template_file.namesvr-sidecar.*.rendered[1]}"
    task-namesvr-sidecar2 = "${data.template_file.namesvr-sidecar.*.rendered[2]}"
    task-dledger-sidecar0 = "${data.template_file.dledger-sidecar.*.rendered[0]}"
    task-dledger-sidecar1 = "${data.template_file.dledger-sidecar.*.rendered[1]}"
    task-dledger-sidecar2 = "${data.template_file.dledger-sidecar.*.rendered[2]}"
  }
}
resource "nomad_job" "namesvr" {
  count = "${length(local.az)}"
  jobspec = "${data.template_file.broker-job.*.rendered[count.index]}"
}