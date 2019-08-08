locals {
  az             = data.terraform_remote_state.nomad.outputs.az
  namesvr-name   = "namesvc-service-${var.clusterId}"
  brokersvc-name = "brokersvc-service-${var.clusterId}"
  region         = data.terraform_remote_state.nomad.outputs.region
}

module "consulKeys" {
  source    = "./consulKeys"
  address   = "${data.terraform_remote_state.nomad.outputs.consul_servers_public_ips[0]}:8500"
  clusterId = var.clusterId
  region    = local.region
}

module "namesvr" {
  source                     = "./namesvr"
  rocketmq_docker_image      = var.rocketmq_docker_image
  rocketmq_version           = var.rocketmq_version
  namesvc-name               = local.namesvr-name
  az                         = local.az
  cluster-id                 = var.clusterId
  nomad-server-ip            = data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]
  region                     = data.terraform_remote_state.nomad.outputs.region
  allow-multiple-tasks-in-az = false
}

module "console" {
  source = "./console"
  namesvc_name = local.namesvr-name
  region = local.region
  clusterId = var.clusterId
  nomad_ip = data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]
}

module "loadBalanceWatcher" {
  source          = "./loadBalancer"
  az              = data.terraform_remote_state.nomad.outputs.az[0]
  nomad-server-ip = data.terraform_remote_state.nomad.outputs.nomad_servers_ips[0]
  region          = data.terraform_remote_state.nomad.outputs.region
  terraform-image = var.terraform-image
  clusterId       = var.clusterId
  jobName         = "loadBalanceWatcher-${var.clusterId}"
  projectId       = data.terraform_remote_state.nomad.outputs.projectId
  vpcId           = data.terraform_remote_state.nomad.outputs.clientVpcId
  subnetId        = data.terraform_remote_state.nomad.outputs.clientSubnetId
  ucloud_pubkey   = var.ucloud_pubkey
  ucloud_secret   = var.ucloud_secret
}

