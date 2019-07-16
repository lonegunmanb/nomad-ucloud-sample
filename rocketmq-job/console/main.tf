variable "namesvc_name" {}

data "terraform_remote_state" "nomad" {
  backend = "local"
  config = {
    path = "${path.module}/../../terraform.tfstate"
  }
}

provider "nomad" {
  address = "http://${data.terraform_remote_state.nomad.nomad_servers_ips[0]}:4646"
  region  = "cn-bj2"
}

locals {
  az = "${data.terraform_remote_state.nomad.az}"
  cluster-id = "${data.terraform_remote_state.nomad.cluster_id}"
  console-job-hcl = "${path.module}/console-job.hcl"
  namesvc-sidecar-hcl = "${path.module}/namesvc-sidecar.hcl"
}

data "template_file" "namesvr-sidecar" {
  count = "${length(local.az)}"
  template = "${file(local.namesvc-sidecar-hcl)}"
  vars {
    cluster-id = "${data.terraform_remote_state.nomad.cluster_id}"
    index = "${count.index}"
  }
}

data "template_file" "console-job" {
  template = "${file(local.console-job-hcl)}"
  vars = {
    cluster-id = "${local.cluster-id}"
    console-image = "uhub.service.ucloud.cn/lonegunmanb/rocketmq-console-ng:latest"
    namesvc-name = "${var.namesvc_name}"
    az = "${local.az[0]}"
    task-namesvr-sidecar0 = "${data.template_file.namesvr-sidecar.*.rendered[0]}"
    task-namesvr-sidecar1 = "${data.template_file.namesvr-sidecar.*.rendered[1]}"
    task-namesvr-sidecar2 = "${data.template_file.namesvr-sidecar.*.rendered[2]}"
  }
}

resource "nomad_job" "console" {
  jobspec = "${data.template_file.console-job.rendered}"
}