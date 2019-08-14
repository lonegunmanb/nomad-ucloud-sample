variable rocketmq_version {}
variable rocketmq_docker_image {}
variable namesvc-name {
}
variable az {
  type = list(string)
}
variable region {}
variable cluster-id {}
variable nomad-server-ip {}
variable allow_multiple_tasks_in_az {}

provider nomad {
  address = "http://${var.nomad-server-ip}:4646"
  region  = var.region
}

locals {
  job-hcl = "${path.module}/namesvr-job.hcl"
}

data "template_file" "namesvr-job" {
  template = file(local.job-hcl)
  vars = {
    job-name          = "namesvr-${var.cluster-id}"
    namesvr-image     = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    cmd               = "./mqnamesrv"
    cluster-id        = var.cluster-id
    namesvc-name      = var.namesvc-name
    region            = var.region
    count             = length(var.az)
    min-az-count      = length(distinct(var.az))
    node-class        = "nameServer"
    task-limit-per-az = var.allow_multiple_tasks_in_az ? length(var.az) : 1
  }
}

resource "nomad_job" "namesvr" {
  jobspec = data.template_file.namesvr-job.rendered
}

