variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable region {}
variable ucloud_api_base_url {}

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
  base_url = var.ucloud_api_base_url
}

{{range service "nameServer${cluster-id}"}}
resource "ucloud_lb_attachment" "nameServer-{{.Node}}" {
#{{.Address}}
    load_balancer_id = "${load_balancer_id}"
    listener_id      = "${nameServerListenerId}"
    resource_id      = "{{.Node}}"
    port             = {{.Port}}
}
{{end}}

{{range service "console${cluster-id}"}}
resource "ucloud_lb_attachment" "console-{{.Node}}" {
#{{.Address}}
    load_balancer_id = "${load_balancer_id}"
    listener_id      = "${consoleListenerId}"
    resource_id      = "{{.Node}}"
    port             = {{.Port}}
}
{{end}}