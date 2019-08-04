variable region {}
variable az {
  type = list(string)
}
locals {
  instance_count = length(var.az)
}
variable root_password {}
variable sg_id {}
variable vpc_id {}
variable subnet_id {}
variable data_volume_size {}
variable image_id {}
variable cluster_id {}
variable instance_type {}