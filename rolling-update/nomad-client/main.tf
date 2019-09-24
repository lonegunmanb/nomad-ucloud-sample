variable "root_password" {}
variable "nomad_client_ips" {
  type = list(string)
}
variable "module" {}

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
    command = "terraform taint ${var.module}.ucloud_instance.nomad_clients[${count.index}]"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform taint ${var.module}.null_resource.setup[${count.index}]"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/../../"
    command = "terraform apply --auto-approve -target=${var.module}.ucloud_instance.nomad_clients[${count.index}] -target=${var.module}.ucloud_disk_attachment.disk_attachment[${count.index}] -target=${var.module}.ucloud_eip_association.nomad_ip[${count.index}] -target=${var.module}.null_resource.setup[${count.index}]"
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.nomad_client_ips[count.index]
    }
    inline = [
      file("${path.module}/ensure_nomad_ready.sh")
    ]
  }
}
