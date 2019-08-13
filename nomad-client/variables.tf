variable region {}
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
variable consul_server_public_ips {
  type = list(string)
}
variable data_volume_size {}
variable class {}
variable "TF_PLUGIN_CONSUL_VERSION" {
  default = "2.5.0"
}
variable "TF_PLUGIN_NULL_VERSION" {
  default = "2.1.2"
}
variable "TF_PLUGIN_TEMPLATE_VERSION" {
  default = "2.1.2"
}
variable "TF_PLUGIN_UCLOUD_VERSION" {
  default = "1.11.1"
}
variable provision_from_kun {
  type = bool
  default = false
}
variable ipv6_server_url {}
variable region_id {}