variable ucloud_pub_key {}
variable region {}
variable ucloud_secret {}
variable project_id {}

variable ucloud_api_base_url {}

variable vpcName {}
variable vpc_cidr {}
variable subnetName {}
variable subnet_cidr {}

locals {
  cluster_id = terraform.workspace
}

