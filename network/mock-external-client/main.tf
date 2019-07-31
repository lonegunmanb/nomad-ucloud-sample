variable externalVpcCidr {}
variable project_id {}
variable region {}
variable az {}
variable ucloud_pub_key {}
variable ucloud_secret {}
variable mockServerImageId {}
variable ssh_password {}

data terraform_remote_state mainVpc {
  backend = "local"
  config = {
    path = "../terraform.tfstate"
  }
}

locals {
  cluster_id = data.terraform_remote_state.mainVpc.outputs.cluster_id
  clientVpcId = data.terraform_remote_state.mainVpc.outputs.clientVpcId
  externalVpcName = "externalVpc-${local.cluster_id}"
  externalSubnetName = "externalVpc-${local.cluster_id}"
}
module externalVpc {
  source = "../vpc"
  cidr = var.externalVpcCidr
  cluster_id = local.cluster_id
  project_id = var.project_id
  region = var.region
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
  vpcName = local.externalVpcName
  subnetName = local.externalSubnetName
}

provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
}

resource ucloud_vpc_peering_connection externalPeerinng {
  peer_vpc_id = local.clientVpcId
  vpc_id = module.externalVpc.vpc_id
}

resource ucloud_instance mockServer {
  name = "nomad-mockserver"
  availability_zone = var.az
  image_id = var.mockServerImageId
  instance_type = "n-highcpu-1"
  vpc_id = module.externalVpc.vpc_id
  subnet_id = module.externalVpc.subnetId
  root_password = "psXMKfJ6ZYcEsv9SFkhz"
}

resource "ucloud_eip" mockServer {
  name = "nomad-mockserver"
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = "dynamic"
  bandwidth     = 200
  tag           = local.cluster_id
}

resource "ucloud_eip_association" "nomad_ip" {
  eip_id      = ucloud_eip.mockServer.id
  resource_id = ucloud_instance.mockServer.id
}

output eip {
  value = ucloud_eip.mockServer.public_ip
}