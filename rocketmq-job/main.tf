data "terraform_remote_state" "nomad" {
  backend = "local"
  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}
locals {
  az = "${data.terraform_remote_state.nomad.az}"
  cluster-id = "${data.terraform_remote_state.nomad.cluster_id}"
  namesvr-name = "namesvc-service-${local.cluster-id}"
  brokersvc-name = "brokersvc-service-${local.cluster-id}"
  region = "${data.terraform_remote_state.nomad.region}"
}

module "consulKeys" {
  source = "./consulKeys"
  address = "${data.terraform_remote_state.nomad.consul_servers_public_ips[0]}:8500"
  clusterId = "${local.cluster-id}"
  region = "${local.region}"
  pubkey = "${var.ucloud_pubkey}"
  secret = "${var.ucloud_secret}"
  vpcId = "${data.terraform_remote_state.nomad.vpcId}"
  nomadSubnetId = "${data.terraform_remote_state.nomad.nomadSubnetId}"
  nameServerIds = "${data.terraform_remote_state.nomad.namesvr_ids}"
  nameServerPrivateIps = "${data.terraform_remote_state.nomad.namesvr_private_ips}"
  projectId = "${data.terraform_remote_state.nomad.projectId}"
  brokerServerIds = "${data.terraform_remote_state.nomad.brokersvr_ids}"
  brokerServerPrivateIps = "${data.terraform_remote_state.nomad.brokersvr_private_ips}"
}

module "namesvr" {
  source = "./namesvr"
  rocketmq_docker_image = "${var.rocketmq_docker_image}"
  rocketmq_version = "${var.rocketmq_version}"
  namesvc-name = "${local.namesvr-name}"
  az = "${local.az}"
  cluster-id = "${local.cluster-id}"
  nomad-server-ip = "${data.terraform_remote_state.nomad.nomad_servers_ips[0]}"
}

module "broker" {
  source = "./broker"
  rocketmq_docker_image = "${var.rocketmq_docker_image}"
  rocketmq_version = "${var.rocketmq_version}"
  brokersvc_name = "${local.brokersvc-name}"
  namesvc_name = "${local.namesvr-name}"
}

module "console" {
  source = "./console"
  namesvc_name = "${local.namesvr-name}"
}

module "loadBalanceWatcher" {
  source = "./loadBalancer"
  az = "${data.terraform_remote_state.nomad.az[0]}"
  nomad-server-ip = "${data.terraform_remote_state.nomad.nomad_servers_ips[0]}"
  region = "${data.terraform_remote_state.nomad.region}"
  terraform-image = "${var.terraform-image}"
  clusterId = "${local.cluster-id}"
  jobName = "loadBalanceWatcher-${local.cluster-id}"
}