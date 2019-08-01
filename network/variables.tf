variable az {}
variable ucloud_pub_key {}
variable region {}
variable ucloud_secret {}
variable project_id {}
variable cluster_id {}
variable mgrVpcCidr {}
variable clientVpcCidr {}
variable controllerVpcId {}

locals {
  mgrVpcName = "nomadMgrVpc-${var.cluster_id}"
  mgrSubnetName = "nomadMgrSubnet-${var.cluster_id}"
  clientVpcName = "nomadClientVpc-${var.cluster_id}"
  clientSubnetName = "nomadClientSubnet-${var.cluster_id}"
}

variable externalVpcCidr {}
locals {
  externalVpcName = "externalVpc-${var.cluster_id}"
  externalSubnetName = "externalVpc-${var.cluster_id}"
}