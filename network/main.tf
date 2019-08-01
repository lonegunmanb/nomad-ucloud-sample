module mgrVpc {
  source = "./vpc"
  cidr = var.mgrVpcCidr
  cluster_id = var.cluster_id
  project_id = var.project_id
  region = var.region
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
  vpcName = local.mgrVpcName
  subnetName = local.mgrSubnetName
}

module clientVpc {
  source = "./vpc"
  cidr = var.clientVpcCidr
  cluster_id = var.cluster_id
  project_id = var.project_id
  region = var.region
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
  vpcName = local.clientVpcName
  subnetName = local.clientSubnetName
}

provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
}

resource ucloud_vpc_peering_connection peering {
  peer_vpc_id = module.mgrVpc.vpc_id
  vpc_id = module.clientVpc.vpc_id
}

resource ucloud_vpc_peering_connection controller_peering0 {
  peer_vpc_id = module.mgrVpc.vpc_id
  vpc_id = var.controllerVpcId
}

resource ucloud_vpc_peering_connection controller_peering1 {
  peer_vpc_id = module.clientVpc.vpc_id
  vpc_id = var.controllerVpcId
}