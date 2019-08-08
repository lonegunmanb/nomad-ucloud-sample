variable namesvc_name {}
variable clusterId {}
variable region {}
variable nomad_ip {}

locals {
  console-job-hcl = "${path.module}/console-job.hcl"
}

provider "nomad" {
  address = "http://${var.nomad_ip}:4646"
  region  = var.region
}

data "template_file" "console-job" {
  template = file(local.console-job-hcl)
  vars = {
    cluster-id    = var.clusterId
    console-image = "uhub.service.ucloud.cn/lonegunmanb/rocketmq-console-ng:latest"
    namesvc-name  = var.namesvc_name
    region        = var.region
  }
}

resource "nomad_job" "console" {
  jobspec = data.template_file.console-job.rendered
}

