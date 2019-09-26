variable branch {}
variable consul_backend_root_password {}
variable consul_backend_data_volume_size {}
variable consul_backend_instance_type {}
variable cluster_id {}
variable project_dir {}
variable terraform_project_url {}
variable bootstrapper_image {}
variable controller_image {}
variable k8s_namespace {}
variable k8s_storage_class_name {}
variable region {}
variable region_id {}
variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable ucloud_api_base_url {}
variable controller_cidr {}
variable mgrVpcCidr {}
variable clientVpcCidr {}
variable allow_ip {}
variable az {
  type = list(string)
}
variable ipv6_api_url {}
variable consul_server_image_id {}
variable consul_server_root_password {}
variable consul_server_type {}
variable nomad_client_broker_type {}
variable nomad_client_image_id {}
variable nomad_client_namesvr_type {}
variable nomad_client_root_password {}
variable nomad_server_image_id {}
variable nomad_server_root_password {}
variable nomad_server_type {}
variable broker_count {
  type = number
}
variable name_server_count {
  type = number
}
variable nomad_server_count {
  type = number
}
variable name_server_local_disk_type {}
variable name_server_udisk_type {}
variable name_server_data_disk_size {
  type = number
}
variable broker_local_disk_type {}
variable broker_udisk_type {}
variable broker_data_disk_size {
  type = number
}
variable name_server_use_udisk {
  type = bool
}
variable broker_use_udisk {
  type = bool
}
variable nomad_server_use_udisk {
  type = bool
}
variable nomad_server_local_disk_type {}
variable nomad_server_udisk_type {}
variable nomad_server_data_disk_size {
  type = number
}
variable consul_server_data_disk_size {
  type = number
}
variable consul_server_local_disk_type {}
variable consul_server_udisk_type {}
variable consul_server_use_udisk {
  type = bool
}
variable controller_count {
  type = number
}
variable controller_request_cpu {}
variable controller_limit_cpu {}
variable controller_request_memory {}
variable controller_limit_memory {}
variable controller_svc_port {
  type = number
}
variable controller_pod_port {
  type = number
}
variable controller_env_map {
  type = map(string)
}
variable controller_image_repo {}
variable controller_image_username {}
variable controller_image_password {}
variable fabio_image_id {}
variable prometheus_image_id {}
variable namesvr_http_endpoint_port {}
variable prometheus_port {}
variable charge_type {
  default = "dynamic"
}
variable duration {
  type = number
  default = 1
}
variable env_name {}
variable "legacy_vpc_id" {
  default = ""
}
variable "legacy_subnet_id" {
  default = ""
}
