variable "consul_server_root_password" {
}

variable "nomad_server_root_password" {
}

variable "nomad_client_root_password" {
}

variable "ucloud_pub_key" {
}

variable "ucloud_secret" {
}

variable "region" {
  default = "cn-bj2"
}

variable "az" {
  default = [
    "cn-bj2-02",
    "cn-bj2-03",
    "cn-bj2-04",
  ]
}

variable "project_id" {
}

variable clientSubnetCidr {}
variable mgrSubnetCidr {}

variable "consul_server_type" {
  default = "n-highcpu-1"
}

variable "nomad_server_type" {
  default = "n-highcpu-1"
}

variable "nomad_client_namesvr_type" {
  default = "n-highmem-1"
}

variable "nomad_client_broker_type" {
  default = "n-highmem-1"
}

variable "allow_ip" {
  default = "0.0.0.0/0"
}

variable "consul_server_image_id" {
}

variable "nomad_server_image_id" {
}

variable "nomad_client_image_id" {
}

locals  {
  cluster_id = terraform.workspace
}
variable remote_state_backend_url {}

variable ipv6_server_url {
  default = ""
}
variable region_id {
  default = ""
}
variable provision_from_kun {
  default = false
}
variable ucloud_api_base_url {}
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
variable fabio_image {

}
variable fabio_port {
  type = number
}