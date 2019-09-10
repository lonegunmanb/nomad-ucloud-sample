resource "ucloud_vpc" vpc {
  count = var.legacy_vpc_id != "" ? 0 : 1
  name        = var.vpcName
  cidr_blocks = [var.vpc_cidr]
  tag         = local.cluster_id
}

resource ucloud_subnet subnet {
  count = var.legacy_subnet_id != "" ? 0 : 1
  name = var.subnetName
  cidr_block = var.subnet_cidr
  vpc_id = ucloud_vpc.vpc.*.id[0]
  tag = local.cluster_id
}

data "ucloud_vpcs" "vpc" {
  depends_on = [ucloud_vpc.vpc]
  ids = var.legacy_vpc_id != "" ? [var.legacy_vpc_id] : [ucloud_vpc.vpc.*.id[0]]
}

data "ucloud_subnets" "subnet" {
  depends_on = [ucloud_subnet.subnet]
  ids = var.legacy_subnet_id != "" ? [var.legacy_subnet_id] : [ucloud_subnet.subnet.*.id[0]]
}