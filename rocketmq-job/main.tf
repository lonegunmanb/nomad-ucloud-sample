variable "rocketmq_docker_image" {
  default = "uhub.service.ucloud.cn/lonegunmanb/rocketmq"
}
variable "rocketmq_version" {
  default = "4.5.1"
}

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