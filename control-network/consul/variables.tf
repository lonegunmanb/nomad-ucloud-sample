variable project_id {}
variable ucloud_secret {}
variable ucloud_pub_key {}
variable region {}
variable az {
  type = list(string)
}
locals {
  instance_count = length(var.az)
}
variable root_password {}
variable tag {}
variable vpc_id {}
variable subnet_id {}
variable data_volume_size {}
variable image_id {}
variable instance_type {}