variable az {}
variable ucloud_pub_key {}
variable region {}
variable ucloud_secret {}
variable project_id {}
variable cidr {
  type = "string"
}
variable vpcName {}
variable subnetName {}
variable tag {
  type = "string"
  default = "rocketmq"
}
variable consul_image_id {}
variable controller_image_id {}
variable controler_instance_type {}
variable allow_ip {}
variable root_password {}

locals {
  instanceCount = length(var.az)
}

variable terraform_project_url {}
variable project_root_dir {}
variable project_dir {}
variable consul_root_password {}
variable consul_data_volume_size {}
variable consul_instance_type {}

variable charge_type {
  default = "dynamic"
}

variable "controller_count" {}