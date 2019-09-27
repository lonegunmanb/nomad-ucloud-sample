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
  target = {for i, ip in var.nomad_client_ips: i => ip if i % length(var.az) == var.mod}
}
locals {
  path = "${path.module}/../../"
}

resource "null_resource" "set_ineligiblty" {
  for_each = local.target
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
      "nomad node eligibility -self -disable"
    ]
  }
}

resource "null_resource" "update" {
  for_each = local.target
  triggers = {
    trigger = uuid()
  }
  depends_on = [null_resource.set_ineligiblty]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = each.value
    }
    inline = [
      "echo draining node",
      "nomad node drain -self -enable"
    ]
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform taint ${var.module}.ucloud_instance.nomad_clients[${each.key}]"
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform taint ${var.module}.null_resource.setup[${each.key}]"
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform taint ${var.module}.ucloud_eip.nomad_clients[${each.key}]"
    on_failure = "continue"
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform apply --auto-approve -target=${var.module}.ucloud_instance.nomad_clients[${each.key}] -target=${var.module}.null_resource.setup[${each.key}] -target=${var.module}.ucloud_eip.nomad_clients[${each.key}] -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
  provisioner "local-exec" {
    working_dir = local.path
    command = "terraform apply --auto-approve -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
}
