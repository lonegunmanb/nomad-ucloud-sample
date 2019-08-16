provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url    = var.ucloud_api_base_url
}

resource "ucloud_vpc" vpc {
  name        = var.vpcName
  cidr_blocks = [var.cidr]
  tag         = var.cluster_id
}

resource ucloud_subnet subnet {
  name = var.subnetName
  cidr_block = var.cidr
  vpc_id = ucloud_vpc.vpc.id
  tag = var.cluster_id
}