variable "rocketmq_version" {}
variable "rocketmq_docker_image" {}
variable "namesvc-name" {}
variable "az" {
  type = "list"
}
variable "cluster-id" {}
variable "nomad-server-ip" {}


provider "nomad" {
  address = "http://${var.nomad-server-ip}:4646"
  region  = "cn-bj2"
}
locals {
  job-hcl = "${path.module}/namesvr-job.hcl"
}

data "template_file" "namesvr-job" {
  count = "${length(var.az)}"
  template = "${file(local.job-hcl)}"
  vars = {
    job-name = "namesvr-${var.cluster-id}-${count.index}"
    namesvr-image = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    cmd = "./mqnamesrv"
    cluster-id = "${var.cluster-id}"
    namesvc-name = "${var.namesvc-name}"
    az = "${var.az[count.index]}"
    index = "${count.index}"
    node-class = "nameServer"
  }
}
resource "nomad_job" "namesvr" {
  count = "${length(var.az)}"
  jobspec = "${data.template_file.namesvr-job.*.rendered[count.index]}"
}