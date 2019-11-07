
locals {
  namesvr_clusterId  = terraform.workspace
  namesvr-name       = "namesvc-service-${local.namesvr_clusterId}"
}

provider "ucloud" {
  public_key = var.ucloud_pubkey
  private_key = var.ucloud_secret
  project_id = var.project_id
  region = var.region
  base_url = var.ucloud_api_base_url
}

resource ucloud_lb rocketMQLoadBalancer {
  count = var.internal_use ? 0 : 1
  name = "RocketMQLb-${local.namesvr_clusterId}"
  tag = local.namesvr_clusterId
  internal = "false"
  vpc_id = var.vpcId
  subnet_id = var.subnetId
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
  address = var.consul_access_url
  datacenter = var.region
}

resource "consul_keys" "namesvr_backend_state" {
  count = length(var.az)
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
  az                         = var.az
  cluster-id                 = local.namesvr_clusterId
  nomad-server-address            = var.nomad_server_address
  region                     = var.region
  allow_multiple_tasks_in_az = var.allow_multiple_tasks_in_az
  terraform-image            = var.terraform-image
  ucloud_pubkey              = var.ucloud_pubkey
  ucloud_secret              = var.ucloud_secret
  ucloud_api_base_url        = var.ucloud_api_base_url
  projectId                  = var.project_id
  load_balancer_id           = var.internal_use ? "" : ucloud_lb.rocketMQLoadBalancer.*.id[0]
  nameServerListenerId       = var.internal_use ? "" : ucloud_lb_listener.nameServerListener.*.id[0]
  golang-image               = var.golang-image
  internal_use               = var.internal_use
  cpu                        = var.namesvr_cpu
  memory                     = var.namesvr_memory
}

module "console" {
  source               = "./console"
  namesvc_name         = local.namesvr-name
  region               = var.region
  clusterId            = local.namesvr_clusterId
  nomad_server_address = var.nomad_server_address
  projectId            = var.project_id
  ucloud_api_base_url  = var.ucloud_api_base_url
  ucloud_pub_key       = var.ucloud_pubkey
  ucloud_secret        = var.ucloud_secret
  terraform-image      = var.terraform-image
  load_balancer_id     = var.internal_use ? "" : ucloud_lb.rocketMQLoadBalancer.*.id[0]
  consoleListenerId    = var.internal_use ? "" : ucloud_lb_listener.consoleListener.*.id[0]
  openWebConsole       = true
}
