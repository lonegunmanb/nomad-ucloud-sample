variable "root_password" {}
variable "nomad_client_ips" {
  type = list(string)
}
variable "resource" {}

resource "null_resource" "update" {
  count = length(var.nomad_client_ips)
  triggers = {
    trigger = uuid()
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.nomad_client_ips[count.index]
    }
    inline = [
      "echo draining node",
      "nomad node drain -self -enable"
    ]
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform apply --auto-approve -target=${var.resource}[${count.index}]"
    environment = {
      TF_LOG = ""
    }
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.nomad_client_ips[count.index]
    }
    inline = [
      "echo stop drain node",
      "nomad node drain -self -disable"
    ]
  }
}
