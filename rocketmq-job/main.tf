variable "rocketmq_docker_image" {
  default = "uhub.service.ucloud.cn/lonegunmanb/rocketmq"
}
variable "rocketmq_version" {
  default = "4.5.1"
}

# Configure the Consul provider


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

provider "consul" {
  address    = "${data.terraform_remote_state.nomad.consul_servers_public_ips[0]}:8500"
  datacenter = "${local.region}"
}

resource "consul_keys" "app" {
  count = "${length(data.terraform_remote_state.nomad.nomad_client_private_ips)}"
  key {
    path  = "nomad_client_index/${data.terraform_remote_state.nomad.nomad_client_private_ips[count.index]}"
    value = "${count.index}"
  }
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