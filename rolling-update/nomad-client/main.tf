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
    command = "terraform apply --auto-approve -target=${var.module}.ucloud_instance.nomad_clients[${each.key}] -target=${var.module}.ucloud_disk_attachment.disk_attachment[${each.key}] -target=${var.module}.ucloud_eip_association.nomad_ip[${each.key}] -target=${var.module}.null_resource.setup[${each.key}]"
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = each.value
    }
    inline = [
      file("${path.module}/ensure_nomad_ready.sh")
    ]
  }
}
