variable region {}
variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable ucloud_api_base_url {}
variable az {
  type = list(string)
}
locals {
  instance_count = 3
}
variable root_password {
  type = list(string)
}
variable sg_id {}
variable vpc_id {}
variable subnet_id {}
variable image_id {
  type = list(string)
}
variable cluster_id {}
variable instance_type {
  type = list(string)
}
variable env_name {}
variable ipv6_server_url {}
variable region_id {}
variable use_udisk {
  type = list(bool)
}
variable local_disk_type {
  type = list(string)
}
variable udisk_type {
  type = list(string)
}
variable data_volume_size {
  type = list(number)
}
variable charge_type {
  type = list(string)
  default = ["dynamic"]
}
variable duration {
  type    = list(number)
  default = [1]
}
