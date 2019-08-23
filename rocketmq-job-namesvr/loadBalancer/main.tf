provider "ucloud" {
  public_key = var.ucloud_pubkey
  private_key = var.ucloud_secret
  project_id = var.projectId
  region = var.region
  base_url = var.ucloud_api_base_url
}

resource ucloud_lb rocketMQLoadBalancer {
  name = "RocketMQLb-${var.clusterId}"
  tag = var.clusterId
  internal = "false"
  vpc_id = var.vpcId
  subnet_id = var.subnetId
}

resource ucloud_eip rocketMQLoadBalancer {
  bandwidth            = 200
  charge_mode          = "traffic"
  name                 = "rocketmq-namesvr-lb-${var.clusterId}"
  tag                  = var.clusterId
  internet_type        = "bgp"
}

resource ucloud_eip_association rocketMQLoadBalancer {
  resource_id   = ucloud_lb.rocketMQLoadBalancer.id
  eip_id        = ucloud_eip.rocketMQLoadBalancer.id
}

resource ucloud_lb_listener nameServerListener {
  load_balancer_id = ucloud_lb.rocketMQLoadBalancer.id
  protocol         = "tcp"
  listen_type      = "request_proxy"
  port             = 9876
}

resource ucloud_lb_listener consoleListener {
  load_balancer_id = ucloud_lb.rocketMQLoadBalancer.id
  protocol         = "tcp"
  listen_type      = "request_proxy"
  port             = 8080
}

provider "consul" {
  address = var.consul_access_url
  datacenter = var.region
}

resource "consul_keys" "lb_state" {
  key {
    path = "namesvr-lb/${var.clusterId}/lbState"
    delete = true
  }
}

data "template_file" "tf-content" {
  template = file(local.tf-tpl)
  vars = {
    cluster-id = var.clusterId
    load_balancer_id = ucloud_lb.rocketMQLoadBalancer.id
    nameServerListenerId = ucloud_lb_listener.nameServerListener.id
    consoleListenerId = ucloud_lb_listener.consoleListener.id
  }
}

data "template_file" "tf-vars-content" {
  template = file(local.tf-vars-tpl)
  vars = {
    region       = var.region
    ucloudPubKey = var.ucloud_pubkey
    ucloudPriKey = var.ucloud_secret
    projectId    = var.projectId
    ucloud_api_base_url = var.ucloud_api_base_url
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
  depends_on = [
    ucloud_eip_association.rocketMQLoadBalancer,
    ucloud_lb_listener.consoleListener,
    ucloud_lb_listener.nameServerListener,
    consul_keys.lb_state
  ]
  jobspec = data.template_file.job.rendered
}

