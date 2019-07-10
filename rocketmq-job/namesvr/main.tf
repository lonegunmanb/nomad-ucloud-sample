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
  job-hcl = "${path.module}/namesvr-job.hcl"
}
data "template_file" "namesvr-job" {
  count = "${length(local.az)}"
  template = "${file(local.job-hcl)}"
  vars = {
    job-name = "namesvr-${local.cluster-id}-${count.index}"
    namesvr-image = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    cmd = "./mqnamesrv"
    cluster-id = "${local.cluster-id}"
    az = "${local.az[count.index]}"
    index = "${count.index}"
  }
}
resource "nomad_job" "namesvr" {
  count = "${length(local.az)}"
  jobspec = "${data.template_file.namesvr-job.*.rendered[count.index]}"
}