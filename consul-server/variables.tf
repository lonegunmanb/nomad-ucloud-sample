variable region {}
variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable ucloud_api_base_url {}
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
variable image_id {}
variable cluster_id {}
variable instance_type {}
variable provision_from_kun {
  type = bool
  default = false
}
variable ipv6_server_url {}
variable region_id {}
variable use_udisk {
  type = bool
}
variable local_disk_type {}
variable udisk_type {}
variable data_volume_size {}
