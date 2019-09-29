variable region {}
variable az {
  type = string
}
variable root_password {}
variable sg_id {}
variable vpc_id {}
variable subnet_id {}
variable cluster_id {}
variable instance_count {}
variable image_id {}
variable instance_type {}
variable consul_server_ips {
  type = list(string)
}
variable env_name {}
variable ipv6_server_url {}
variable region_id {}
variable use_udisk {}
variable local_disk_type {
  default = "local_normal" //loacl_ssd cloud_normal cloud_ssd
}
variable udisk_type {
  default = "data_disk" //ssd_data_disk
}
variable data_volume_size {}
variable "duration" {
  type = number
  default = 1
}
variable charge_type {
  default = "dynamic"
}
variable group {
  type = string
}
variable nomad_server_lb_id {
  type = string
}
variable nomad_server_lb_private_ip {
  type = string
}
variable nomad_server_lb_listener_id {
  type = list(string)
}
variable nomad_port {
  type = list(number)
}
