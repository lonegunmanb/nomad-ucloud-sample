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
}

provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url    = var.ucloud_api_base_url
}

resource ucloud_vpc_peering_connection peering {
  depends_on = [module.clientVpc.subnetId, module.mgrVpc.subnetId]
  peer_vpc_id = module.mgrVpc.vpc_id
  vpc_id = module.clientVpc.vpc_id
}

resource ucloud_vpc_peering_connection controller_peering0 {
  count = var.controllerVpcId == "" ? 0 : 1
  depends_on = [module.mgrVpc.subnetId]
  peer_vpc_id = module.mgrVpc.vpc_id
  vpc_id = var.controllerVpcId
}

resource ucloud_vpc_peering_connection controller_peering1 {
  count = var.controllerVpcId == "" ? 0 : 1
  depends_on = [module.clientVpc.subnetId]
  peer_vpc_id = module.clientVpc.vpc_id
  vpc_id = var.controllerVpcId
}