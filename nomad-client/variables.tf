variable region {}
variable az {
  type = list(string)
}
variable root_password {}
variable sg_id {}
variable vpc_id {}
variable subnet_id {}
variable cluster_id {}
variable mgrSubnetCidr {}
variable clientSubnetCidr {}
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