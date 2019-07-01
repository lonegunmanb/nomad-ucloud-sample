variable "consul_server_root_password" {
  default = ""
}
variable "nomad_server_root_password" {
  default = ""
}
variable "nomad_client_root_password" {
  default = ""
}
variable ucloud_pub_key {
  default = ""
}
variable ucloud_secret {
  default = ""
}
variable region {
  default = "cn-bj2"
}
variable az {
  default = [
    "cn-bj2-03",
    "cn-bj2-04",
    "cn-bj2-05"]
}
variable project_id {
  default = ""
}
variable consul_server_type {
  default = "n-standard-1"
}
variable nomad_server_type {
  default = "n-standard-1"
}
variable "nomad_client_type" {
  default = "n-standard-1"
}
variable allow_ip {
  default = "0.0.0.0/0"
}
variable consul_server_image_id {
  default = ""
}
variable nomad_server_image_id {
  default = ""
}
variable nomad_client_image_id {
  default = ""
}