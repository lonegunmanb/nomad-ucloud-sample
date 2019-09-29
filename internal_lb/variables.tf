variable "name" {}
variable "tag" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "instance_ids" {
  type = list(string)
}
variable "ports" {
  type = list(number)
}
variable "listenerName" {
  default = ""
}
variable "device" {
  default = "lo:1"
}
variable "attachment_count" {
  type = number
  default = 0
}
variable "attachment_only" {
  default = false
}
variable "legacy_lb_id" {
  default = ""
}
variable "legacy_lb_private_ip" {
  default = ""
}
variable "legacy_listener_id" {
  type = list(string)
  default = []
}
