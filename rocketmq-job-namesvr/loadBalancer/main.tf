data "template_file" "tf-content" {
  template = file(local.tf-tpl)
  vars = {
    cluster-id = var.clusterId
  }
}

locals {
  tf-vars-tpl = "${path.module}/terraform.tfvars.tpl"
}

data "template_file" "tf-vars-content" {
  template = file(local.tf-vars-tpl)
  vars = {
    clusterId    = var.clusterId
    region       = var.region
    vpcId        = var.vpcId
    subnetId     = var.subnetId
    ucloudPubKey = var.ucloud_pubkey
    ucloudPriKey = var.ucloud_secret
    projectId    = var.projectId
  }
}

data "template_file" "job" {
  template = file(local.job-hcl)
  vars = {
    region          = var.region
    cluster-id      = var.clusterId
    terraform-image = var.terraform-image
    tfvars          = data.template_file.tf-vars-content.rendered
    tf              = data.template_file.tf-content.rendered
    jobName         = var.jobName
  }
}

provider "nomad" {
  address = "http://${var.nomad-server-ip}:4646"
  region  = var.region
}

resource "nomad_job" "terraform_docker" {
  jobspec = data.template_file.job.rendered
}

