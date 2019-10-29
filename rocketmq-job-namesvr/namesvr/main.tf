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
variable ucloud_api_base_url {}
variable projectId {}
variable ucloud_pubkey {}
variable ucloud_secret {}
variable load_balancer_id {}
variable nameServerListenerId {}
variable terraform-image {}
variable internal_use {
  type = bool
}

provider nomad {
  address = "http://${var.nomad-server-ip}:4646"
  region  = var.region
}

locals {
  job-hcl = "${path.module}/namesvr-job.hcl"
}

variable "golang-image" {}
variable "cpu" {}
variable "memory" {}
data "template_file" "namesvr-job" {
  template = file(local.job-hcl)
  vars     = {
    job-name             = "namesvr-${var.cluster-id}"
    namesvr-image        = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    cmd                  = "./mqnamesrv"
    cluster-id           = var.cluster-id
    namesvc-name         = var.namesvc-name
    region               = var.region
    count                = length(var.az)
    min-az-count         = length(distinct(var.az))
    node-class           = "nameServer"
    task-limit-per-az    = var.allow_multiple_tasks_in_az ? length(var.az) : 1
    ucloud_api_base_url  = var.ucloud_api_base_url
    projectId            = var.projectId
    ucloudPubKey         = var.ucloud_pubkey
    ucloudPriKey         = var.ucloud_secret
    load_balancer_id     = var.load_balancer_id
    nameServerListenerId = var.nameServerListenerId
    terraform-image      = var.terraform-image
    golang-image         = var.golang-image
    attachment-count     = var.internal_use ? 0 : 1
    cpu                  = var.cpu
    memory               = var.memory
  }
}

resource "nomad_job" "namesvr" {
  jobspec = data.template_file.namesvr-job.rendered
}

