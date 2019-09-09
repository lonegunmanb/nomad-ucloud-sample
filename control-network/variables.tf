variable az {}
variable ucloud_pub_key {}
variable region {}
variable region_id {}
variable ucloud_secret {}
variable project_id {}
variable ucloud_api_base_url {}
variable cidr {
  type = "string"
}
variable vpcName {}
variable subnetName {}
variable tag {
  type = "string"
  default = "rocketmqbackend"
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
variable git_branch {}
variable project_root_dir {}
variable project_dir {}
variable consul_backend_root_password {}
variable consul_backend_data_volume_size {}
variable consul_backend_instance_type {}

variable charge_type {
  default = "dynamic"
}
variable duration {
  type = number
  default = 1
}

variable "controller_count" {}
variable "ipv6_api_url" {}
variable provision_from_kun {
  type = bool
  default = false
}
locals {
  reconfig_ssh_keys_script = file("./reconfig_ssh_keys.sh")
}