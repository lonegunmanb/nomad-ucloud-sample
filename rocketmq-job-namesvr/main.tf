locals {
  namesvr_clusterId = terraform.workspace
  az             = data.terraform_remote_state.nomad.outputs.az
  namesvr-name   = "namesvc-service-${local.namesvr_clusterId}"
  region         = data.terraform_remote_state.nomad.outputs.region
  project_id = data.terraform_remote_state.nomad.outputs.projectId
  nomadServerAddress    = length(data.terraform_remote_state.nomad.outputs.nomad_server_ip) > 15 ? "[${data.terraform_remote_state.nomad.outputs.nomad_server_ip}]":data.terraform_remote_state.nomad.outputs.nomad_server_ip
  vpcId           = data.terraform_remote_state.nomad.outputs.clientVpcId
  subnetId        = data.terraform_remote_state.nomad.outputs.clientSubnetId
}

provider "ucloud" {
  public_key = var.ucloud_pubkey
  private_key = var.ucloud_secret
  project_id = local.project_id
  region = local.region
  base_url = var.ucloud_api_base_url
}

resource ucloud_lb rocketMQLoadBalancer {
  count = var.internal_use ? 0 : 1
  name = "RocketMQLb-${local.namesvr_clusterId}"
  tag = local.namesvr_clusterId
  internal = "false"
  vpc_id = local.vpcId
  subnet_id = local.subnetId
}

resource ucloud_eip nameSvrLoadBalancer {
  count = var.internal_use ? 0 : 1
  bandwidth            = 200
  charge_mode          = "traffic"
  name                 = "rocketmq-namesvr-lb-${local.namesvr_clusterId}"
  tag                  = local.namesvr_clusterId
  internet_type        = "bgp"
}

resource ucloud_eip_association rocketMQLoadBalancer {
  count = var.internal_use ? 0 : 1
  resource_id   = ucloud_lb.rocketMQLoadBalancer.*.id[0]
  eip_id        = ucloud_eip.nameSvrLoadBalancer.*.id[0]
}

resource ucloud_lb_listener nameServerListener {
  count = var.internal_use ? 0 : 1
  load_balancer_id = ucloud_lb.rocketMQLoadBalancer.*.id[0]
  protocol         = "tcp"
  listen_type      = "request_proxy"
  port             = 9876
}

resource ucloud_lb_listener consoleListener {
  count = var.internal_use ? 0 : 1
  load_balancer_id = ucloud_lb.rocketMQLoadBalancer.*.id[0]
  protocol         = "tcp"
  listen_type      = "request_proxy"
  port             = 8080
}

provider "consul" {
  address = local.consul_access_url
  datacenter = local.region
}

resource "consul_keys" "namesvr_backend_state" {
  count = length(local.az)
  key {
    path = "namesvr-lb/${local.namesvr_clusterId}/namesvr-${count.index}"
    delete = true
  }
}

resource "consul_keys" "console_backend_state" {
  key {
    path = "namesvr-lb/${local.namesvr_clusterId}/console"
    delete = true
  }
}

module "namesvr" {
  source                     = "./namesvr"
  rocketmq_docker_image      = var.rocketmq_docker_image
  rocketmq_version           = var.rocketmq_version
  namesvc-name               = local.namesvr-name
  az                         = local.az
  cluster-id                 = local.namesvr_clusterId
  nomad-server-ip            = local.nomadServerAddress
  region                     = data.terraform_remote_state.nomad.outputs.region
  allow_multiple_tasks_in_az = var.allow_multiple_tasks_in_az
  terraform-image            = var.terraform-image
  ucloud_pubkey              = var.ucloud_pubkey
  ucloud_secret              = var.ucloud_secret
  ucloud_api_base_url        = var.ucloud_api_base_url
  projectId                  = data.terraform_remote_state.nomad.outputs.projectId
  load_balancer_id           = var.internal_use ? "" : ucloud_lb.rocketMQLoadBalancer.*.id[0]
  nameServerListenerId       = var.internal_use ? "" : ucloud_lb_listener.nameServerListener.*.id[0]
  golang-image               = var.golang-image
  internal_use               = var.internal_use
}

module "console" {
  source              = "./console"
  namesvc_name        = local.namesvr-name
  region              = local.region
  clusterId           = local.namesvr_clusterId
  nomad_ip            = local.nomadServerAddress
  projectId           = local.project_id
  ucloud_api_base_url = var.ucloud_api_base_url
  ucloud_pub_key      = var.ucloud_pubkey
  ucloud_secret       = var.ucloud_secret
  terraform-image     = var.terraform-image
  load_balancer_id    = var.internal_use ? "" : ucloud_lb.rocketMQLoadBalancer.*.id[0]
  consoleListenerId   = var.internal_use ? "" : ucloud_lb_listener.consoleListener.*.id[0]
  openWebConsole      = !var.internal_use
}
