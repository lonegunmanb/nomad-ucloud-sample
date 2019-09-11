provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url    = var.ucloud_api_base_url
}

module mgrVpc {
  source = "./vpc"
  cidr = var.mgrVpcCidr
  cluster_id = local.cluster_id
  project_id = var.project_id
  region = var.region
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
  vpcName = local.mgrVpcName
  subnetName = local.mgrSubnetName
  ucloud_api_base_url = var.ucloud_api_base_url
  vpc_count = var.legacy_vpc_id == "" ? 1 : 0
}

module clientVpc {
  source = "./vpc"
  cidr = var.clientVpcCidr
  cluster_id = local.cluster_id
  project_id = var.project_id
  region = var.region
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
  vpcName = local.clientVpcName
  subnetName = local.clientSubnetName
  ucloud_api_base_url = var.ucloud_api_base_url
  vpc_count = var.legacy_vpc_id == "" ? 1 : 0
}

data "ucloud_vpcs" "mgrVpc" {
  ids = var.legacy_vpc_id != "" ? [var.legacy_vpc_id] : [module.mgrVpc.vpc_id]
}

data "ucloud_vpcs" "clientVpc" {
  ids = var.legacy_vpc_id != "" ? [var.legacy_vpc_id] : [module.clientVpc.vpc_id]
}

data "ucloud_subnets" "mgrSubnet" {
  ids = var.legacy_subnet_id != "" ? [var.legacy_subnet_id] : [module.mgrVpc.subnetId]
}

data "ucloud_subnets" "clientSubnet" {
  ids = var.legacy_subnet_id != "" ? [var.legacy_subnet_id] : [module.clientVpc.subnetId]
}

resource ucloud_vpc_peering_connection peering {
  count = var.legacy_vpc_id == "" ? 1 : 0
  depends_on = [data.ucloud_subnets.mgrSubnet, data.ucloud_subnets.clientSubnet]
  peer_vpc_id = data.ucloud_vpcs.mgrVpc.vpcs.*.id[0]
  vpc_id = data.ucloud_vpcs.clientVpc.vpcs.*.id[0]
}

resource ucloud_vpc_peering_connection controller_peering0 {
  count = var.controllerVpcId != "" && var.legacy_vpc_id == "" ? 1 : 0
  depends_on = [data.ucloud_vpcs.mgrVpc]
  peer_vpc_id = data.ucloud_vpcs.mgrVpc.vpcs.*.id[0]
  vpc_id = var.controllerVpcId
}

resource ucloud_vpc_peering_connection controller_peering1 {
  count = var.controllerVpcId != "" && var.legacy_vpc_id == "" ? 1 : 0
  depends_on = [data.ucloud_vpcs.clientVpc]
  peer_vpc_id = data.ucloud_vpcs.clientVpc.vpcs.*.id[0]
  vpc_id = var.controllerVpcId
}