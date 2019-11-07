variable namesvc_name {}
variable clusterId {}
variable region {}
variable nomad_server_address {}
variable ucloud_pub_key {}
variable ucloud_secret {}
variable projectId {}
variable ucloud_api_base_url {}
variable terraform-image {}
variable load_balancer_id {}
variable consoleListenerId {}
variable openWebConsole {
  type = bool
}

locals {
  console-job-hcl = "${path.module}/console-job.hcl"
}

provider "nomad" {
  address = var.nomad_server_address
  region  = var.region
}

data "template_file" "console-job" {
  template = file(local.console-job-hcl)
  vars     = {
    cluster-id          = var.clusterId
    console-image       = "uhub.service.ucloud.cn/lonegunmanb/rocketmq-console-ng:latest"
    terraform-image     = var.terraform-image
    namesvc-name        = var.namesvc_name
    region              = var.region
    ucloudPubKey        = var.ucloud_pub_key
    ucloudPriKey        = var.ucloud_secret
    projectId           = var.projectId
    ucloud_api_base_url = var.ucloud_api_base_url
    load_balancer_id    = var.load_balancer_id
    consoleListenerId   = var.consoleListenerId
    node-class          = "nameServer"
  }
}

resource "nomad_job" "console" {
  count = var.openWebConsole ? 1 : 0
  jobspec = data.template_file.console-job.rendered
}

