variable ucloud_pub_key {}
variable region {}
variable ucloud_secret {}
variable project_id {}
variable mgrVpcCidr {}
variable clientVpcCidr {}
variable controllerVpcId {
  default = ""
}
variable "ucloud_api_base_url" {
}

locals {
  cluster_id = terraform.workspace
  mgrVpcName = "nomadMgrVpc-${local.cluster_id}"
  mgrSubnetName = "nomadMgrSubnet-${local.cluster_id}"
  clientVpcName = "nomadClientVpc-${local.cluster_id}"
  clientSubnetName = "nomadClientSubnet-${local.cluster_id}"
  externalVpcName = "externalVpc-${local.cluster_id}"
  externalSubnetName = "externalVpc-${local.cluster_id}"
}

