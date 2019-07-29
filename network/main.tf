provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
}

resource "ucloud_vpc" "consul_vpc" {
  name        = "nomad-vpc-${var.cluster_id}"
  cidr_blocks = ["10.0.0.0/16"]
  tag         = var.cluster_id
}

resource "ucloud_subnet" "consul_server" {
  name       = "consul-server-subnet-${var.cluster_id}"
  cidr_block = "10.0.0.0/24"
  vpc_id     = ucloud_vpc.consul_vpc.id
  tag        = var.cluster_id
}

resource "ucloud_subnet" "nomad" {
  name       = "nomad-subnet-${var.cluster_id}"
  cidr_block = "10.0.1.0/24"
  vpc_id     = ucloud_vpc.consul_vpc.id
  tag        = var.cluster_id
}

