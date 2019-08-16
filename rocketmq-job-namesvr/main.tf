locals {
  namesvr_clusterId = terraform.workspace
  az             = data.terraform_remote_state.nomad.outputs.az
  namesvr-name   = "namesvc-service-${local.namesvr_clusterId}"
  region         = data.terraform_remote_state.nomad.outputs.region
}

module "namesvr" {
  source                     = "./namesvr"
  rocketmq_docker_image      = var.rocketmq_docker_image
  rocketmq_version           = var.rocketmq_version
  namesvc-name               = local.namesvr-name
  az                         = local.az
  cluster-id                 = local.namesvr_clusterId
  nomad-server-ip            = data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]
  region                     = data.terraform_remote_state.nomad.outputs.region
  allow_multiple_tasks_in_az = var.allow_multiple_tasks_in_az
}

module "console" {
  source = "./console"
  namesvc_name = local.namesvr-name
  region = local.region
  clusterId = local.namesvr_clusterId
  nomad_ip = data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]
}

module "loadBalanceWatcher" {
  source          = "./loadBalancer"
  az              = data.terraform_remote_state.nomad.outputs.az[0]
  nomad-server-ip = data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]
  region          = data.terraform_remote_state.nomad.outputs.region
  terraform-image = var.terraform-image
  clusterId       = local.namesvr_clusterId
  jobName         = "loadBalanceWatcher-${local.namesvr_clusterId}"
  projectId       = data.terraform_remote_state.nomad.outputs.projectId
  vpcId           = data.terraform_remote_state.nomad.outputs.clientVpcId
  subnetId        = data.terraform_remote_state.nomad.outputs.clientSubnetId
  ucloud_pubkey   = var.ucloud_pubkey
  ucloud_secret   = var.ucloud_secret
  ucloud_api_base_url = var.ucloud_api_base_url
}

