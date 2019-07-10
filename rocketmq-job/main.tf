variable "rocketmq_docker_image" {
  default = "uhub.service.ucloud.cn/lonegunmanb/rocketmq"
}
variable "rocketmq_version" {
  default = "4.5.1"
}

module "namesvr" {
  source = "./namesvr"
  rocketmq_docker_image = "${var.rocketmq_docker_image}"
  rocketmq_version = "${var.rocketmq_version}"
}

module "broker" {
  source = "./broker"
  rocketmq_docker_image = "${var.rocketmq_docker_image}"
  rocketmq_version = "${var.rocketmq_version}"
}