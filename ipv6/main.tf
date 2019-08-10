variable disable {
  default = false
}
variable resourceIds {
  type = list(string)
}
variable "api_server_url" {}
variable region_id {}
data "external" "consul_lb_ipv6" {
  count = var.disable ? 0 : length(var.resourceIds)
  program = ["python", "${path.module}/ipv6.py"]
  query = {
    url = var.api_server_url
    resourceId = var.resourceIds[count.index]
    regionId = var.region_id
  }
}

output "ipv6s" {
  value = length(data.external.consul_lb_ipv6.*.result) == 0 ? list(null) : data.external.consul_lb_ipv6.*.result["ip"]
}