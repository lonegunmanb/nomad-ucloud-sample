variable "root_password" {}
variable "nomad_client_ips" {
  type = list(string)
}
variable "module" {}
variable "mod" {
  type = number
}

variable "az" {
  type = list(string)
}
variable "remote_state_backend_url" {}


locals {
  path = "${path.module}/../../"
}

resource "null_resource" "set_ineligiblty" {
  for_each = toset(var.nomad_client_ips)
  triggers = {
    trigger = uuid()
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = each.value
    }
    inline = [
      "echo set node ineligiblty",
      "nomad node eligibility -self -disable",
      "echo draining node",
      "nomad node drain -self -enable"
    ]
  }
}

resource "null_resource" "rolling" {
  depends_on = [null_resource.set_ineligiblty]
  triggers = {
    trigger = uuid()
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "sh taint_module.sh ${var.module}${var.mod}"
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform apply --auto-approve -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform apply --auto-approve -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
}
