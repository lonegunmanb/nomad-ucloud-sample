variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable region {}

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

{{range service "nameServer${cluster-id}"}}
{{$name := key (printf "serversIp2Id/%s" .Address)}}
resource "ucloud_lb_attachment" "{{printf "nameServer%s" $name}}" {
    load_balancer_id = "${load_balancer_id}"
    listener_id      = "${nameServerListenerId}"
    resource_id      = "{{key (printf "serversIp2Id/%s" .Address)}}"
    port             = {{.Port}}
}
{{end}}

{{range service "console${cluster-id}"}}
{{$name := key (printf "serversIp2Id/%s" .Address)}}
resource "ucloud_lb_attachment" "{{printf "console%s" $name}}" {
    load_balancer_id = "${load_balancer_id}"
    listener_id      = "${consoleListenerId}"
    resource_id      = "{{key (printf "serversIp2Id/%s" .Address)}}"
    port             = {{.Port}}
}
{{end}}