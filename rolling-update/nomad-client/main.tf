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

resource "null_resource" "update" {
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
      "echo draining node",
      "nomad node drain -self -enable"
    ]
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform taint ${var.module}.ucloud_instance.nomad_clients[${each.key}]"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform taint ${var.module}.null_resource.setup[${each.key}]"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform taint ${var.module}.ucloud_eip.nomad_clients[${each.key}]"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform apply --auto-approve -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
  //because we use local file to pass namesvrs' ids to internal ulb, so internal ulb's attachments cannot see relations between vserver and uhost
  //terraform apply above destroy old client, and destroy ulb backend in background, which cannot been sensored by terraform because we didn't taint attachments
  //terraform will know the backend it recorded in state file doesn't exist anymore on a second apply, and terraform will re-create backend
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform apply --auto-approve -var 'remote_state_backend_url=${var.remote_state_backend_url}'"
  }
}
