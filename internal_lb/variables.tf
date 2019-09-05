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