variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable region {}
variable vpcId {}
variable subnet_id {}
variable cluster-id {}
variable lb-count {
    default = {{key "lb-${cluster-id}/lbCount"}}
}

terraform {
  backend "consul" {
    address = "{{with service "consul"}}{{with index . 0}}{{.Address}}:8500{{end}}{{end}}"
    scheme = "http"
    path = "lb-${cluster-id}/lbState"
  }
}

provider "ucloud" {
  public_key = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id = var.project_id
  region = var.region
}

resource ucloud_lb rocketMQLoadBalancer {
  count = var.lb-count
  name = "RocketMQLb-$${var.cluster-id}"
  tag = var.cluster-id
  internal = "false"
  vpc_id = var.vpcId
  subnet_id = var.subnet_id
}

resource ucloud_eip rocketMQLoadBalancer {
    count = var.lb-count
    bandwidth            = 200
    charge_mode          = "traffic"
    name                 = "rocketmq-${cluster-id}"
    tag                  = "${cluster-id}"
    internet_type        = "bgp"
}

resource ucloud_eip_association rocketMQLoadBalancer {
    count = var.lb-count
    resource_id   = ucloud_lb.rocketMQLoadBalancer.*.id[count.index]
    eip_id        = ucloud_eip.rocketMQLoadBalancer.*.id[count.index]
}

resource ucloud_lb_listener nameServerListener {
    count = var.lb-count
    load_balancer_id = ucloud_lb.rocketMQLoadBalancer.*.id[count.index]
    protocol         = "tcp"
    listen_type      = "request_proxy"
    port             = 9876
}

resource ucloud_lb_listener consoleListener {
    count = var.lb-count
    load_balancer_id = ucloud_lb.rocketMQLoadBalancer.*.id[count.index]
    protocol         = "tcp"
    listen_type      = "request_proxy"
    port             = 8080
}

{{range service "nameServer${cluster-id}"}}
{{$name := key (printf "serversIp2Id/%s" .Address)}}
resource "ucloud_lb_attachment" "{{printf "nameServer%s" $name}}" {
    count = var.lb-count
    load_balancer_id = ucloud_lb.rocketMQLoadBalancer.*.id[count.index]
    listener_id      = ucloud_lb_listener.nameServerListener.*.id[count.index]
    resource_id      = "{{key (printf "serversIp2Id/%s" .Address)}}"
    port             = {{.Port}}
}
{{end}}

{{range service "console${cluster-id}"}}
{{$name := key (printf "serversIp2Id/%s" .Address)}}
resource "ucloud_lb_attachment" "{{printf "console%s" $name}}" {
    count = var.lb-count
    load_balancer_id = ucloud_lb.rocketMQLoadBalancer.*.id[count.index]
    listener_id      = ucloud_lb_listener.consoleListener.*.id[count.index]
    resource_id      = "{{key (printf "serversIp2Id/%s" .Address)}}"
    port             = {{.Port}}
}
{{end}}