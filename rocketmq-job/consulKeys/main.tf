variable address {}
variable region {}
variable clusterId {}
variable pubkey {}
variable secret {}
variable vpcId {}
variable nomadSubnetId {}
variable "projectId" {}
variable nameServerIds {
  type = "list"
}
variable brokerServerIds {
  type = "list"
}
variable nameServerPrivateIps {
  type = "list"
}
variable brokerServerPrivateIps {
  type = "list"
}

provider "consul" {
  address = "${var.address}"
  datacenter = "${var.region}"
}

resource "consul_keys" "region" {
  key {
    path = "cluster/region"
    value = "${var.region}"
  }
}

resource "consul_keys" "clusterId" {
  key {
    path = "cluster/id"
    value = "${var.clusterId}"
  }
}

resource "consul_keys" "ucloud_pubkey" {
  key {
    path = "cluster/pubkey"
    value = "${var.pubkey}"
  }
}

resource "consul_keys" "ucloud_secret" {
  key {
    path = "cluster/secret"
    value = "${var.secret}"
  }
}

resource "consul_keys" "vpcId" {
  key {
    path = "cluster/vpcId"
    value = "${var.vpcId}"
  }
}

resource "consul_keys" "nomadSubnetId" {
  key {
    path = "cluster/nomadSubnetId"
    value = "${var.nomadSubnetId}"
  }
}

resource "consul_keys" "nameServerIds" {
  count = "${length(var.nameServerIds)}"
  key {
    path = "serversIp2Id/${var.nameServerPrivateIps[count.index]}"
    value = "${var.nameServerIds[count.index]}"
  }
}

resource "consul_keys" "brokerServerIds" {
  count = "${length(var.brokerServerIds)}"
  key {
    path = "serversIp2Id/${var.brokerServerPrivateIps[count.index]}"
    value = "${var.brokerServerIds[count.index]}"
  }
}

resource "consul_keys" "ucloudProjectId" {
  key {
    path = "cluster/projectId"
    value = "${var.projectId}"
  }
}

resource "consul_keys" "lbCount" {
  key {
    path = "lb-${var.clusterId}/lbCount"
    value = "1"
  }
}