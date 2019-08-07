variable "resourceId" {}
variable "api_server_url" {}
variable region_id {}
data "external" "consul_lb_ipv6" {
  program = ["python", "${path.module}/ipv6.py"]
  query = {
    url = var.api_server_url
    resourceId = var.resourceId
    regionId = var.region_id
  }
}

output "ipv6" {
  value = data.external.consul_lb_ipv6.result["ip"]
}