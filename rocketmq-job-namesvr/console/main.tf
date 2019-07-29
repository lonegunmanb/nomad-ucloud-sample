variable namesvc_name {}
variable clusterId {}

data "terraform_remote_state" "nomad" {
  backend = "local"
  config = {
    path = "${path.module}/../../terraform.tfstate"
  }
}

locals {
  region          = data.terraform_remote_state.nomad.outputs.region
  console-job-hcl = "${path.module}/console-job.hcl"
}

provider "nomad" {
  address = "http://${data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]}:4646"
  region  = local.region
}

data "template_file" "console-job" {
  template = file(local.console-job-hcl)
  vars = {
    cluster-id    = var.clusterId
    console-image = "uhub.service.ucloud.cn/lonegunmanb/rocketmq-console-ng:latest"
    namesvc-name  = var.namesvc_name
    region        = local.region
  }
}

resource "nomad_job" "console" {
  jobspec = data.template_file.console-job.rendered
}

