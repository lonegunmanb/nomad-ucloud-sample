variable region {}
variable address {}
variable clusterId {}

provider "consul" {
  address = "${var.address}"
  datacenter = "${var.region}"
}

resource "consul_keys" "lbCount" {
  key {
    path = "lb-${var.clusterId}/lbCount"
    value = "1"
  }
}