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
    path = "lb-${cluster-id}/nameSvrLbState"
  }
}

provider "ucloud" {
  public_key = "$${var.ucloud_pub_key}"
  private_key = "$${var.ucloud_secret}"
  project_id = "$${var.project_id}"
  region = "$${var.region}"
}

resource ucloud_lb nameServerLb {
  count = "$${var.lb-count}"
  name = "NameServerLb-$${var.cluster-id}"
  tag = "$${var.cluster-id}"
  internal = "false"
  vpc_id = "$${var.vpcId}"
  subnet_id = "$${var.subnet_id}"
}

resource ucloud_eip nameServerLb {
    count = "$${var.lb-count}"
    bandwidth            = 200
    charge_mode          = "traffic"
    name                 = "nameServer-${cluster-id}"
    tag                  = "${cluster-id}"
    internet_type        = "bgp"
}

resource ucloud_eip_association nameServerLb {
    count = "$${var.lb-count}"
    resource_id   = "$${ucloud_lb.nameServerLb.*.id[count.index]}"
    eip_id        = "$${ucloud_eip.nameServerLb.*.id[count.index]}"
}

resource ucloud_lb_listener nameServerListener {
    count = "$${var.lb-count}"
    load_balancer_id = "$${ucloud_lb.nameServerLb.*.id[count.index]}"
    protocol         = "tcp"
    listen_type      = "request_proxy"
    port             = 9876
}

{{range service "nameServer${cluster-id}"}}

resource "ucloud_lb_attachment" "{{key (printf "nameServersIp2Id/%s" .Address)}}" {
    count = "$${var.lb-count}"
    load_balancer_id = "$${ucloud_lb.nameServerLb.*.id[count.index]}"
    listener_id      = "$${ucloud_lb_listener.nameServerListener.*.id[count.index]}"
    resource_id      = "{{key (printf "nameServersIp2Id/%s" .Address)}}"
    port             = {{.Port}}
}
{{end}}