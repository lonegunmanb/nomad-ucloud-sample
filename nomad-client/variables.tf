variable region {}
variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable ucloud_api_base_url {}
variable az {
  type = list(string)
}
variable root_password {}
variable sg_id {}
variable vpc_id {}
variable subnet_id {}
variable cluster_id {}
variable instance_count {}
variable image_id {}
variable instance_type {}
variable consul_server_private_ips {
  type = list(string)
}
variable use_udisk {
  type = bool
}
variable local_disk_type {
  default = "local_normal" //loacl_ssd cloud_normal cloud_ssd
}
variable udisk_type {
  default = "data_disk" //ssd_data_disk
}
variable data_volume_size {}
variable class {}
variable provision_from_kun {
  type = bool
  default = false
}
variable ipv6_server_url {}
variable region_id {}
variable "consul_access_url" {}