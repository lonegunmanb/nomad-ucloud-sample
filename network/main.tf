resource "ucloud_vpc" vpc {
  name        = var.vpcName
  cidr_blocks = [var.vpc_cidr]
  tag         = local.cluster_id
  lifecycle {
    prevent_destroy = true
  }
}

resource ucloud_subnet subnet {
  name = var.subnetName
  cidr_block = var.subnet_cidr
  vpc_id = ucloud_vpc.vpc.id
  tag = local.cluster_id
  lifecycle {
    prevent_destroy = true
  }
}