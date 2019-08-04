resource "ucloud_instance" "consul_server" {
  count             = local.instance_count
  name              = "consul-server-${count.index}"
  tag               = var.cluster_id
  availability_zone = var.az[count.index % length(var.az)]
  image_id          = var.image_id
  instance_type     = var.instance_type
  root_password     = var.root_password
  charge_type       = "dynamic"
  security_group    = var.sg_id
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  data_disk_size    = var.data_volume_size
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_eip" "consul_servers" {
  count         = local.instance_count
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = "dynamic"
  bandwidth     = 200
  tag           = var.cluster_id
}

resource "ucloud_eip_association" "consul_ip" {
  count       = local.instance_count
  eip_id      = ucloud_eip.consul_servers[count.index].id
  resource_id = ucloud_instance.consul_server[count.index].id
}

locals {
  setup-script-path             = "${path.module}/setup.sh"
  reconfig-ssh-keys-script-path = "${path.module}/reconfig_ssh_keys.sh"
  reconfig-ssh-keys-script      = file(local.reconfig-ssh-keys-script-path)
}

data "template_file" "setup-script" {
  count    = local.instance_count
  template = file(local.setup-script-path)
  vars = {
    region             = var.region
    node-name          = ucloud_instance.consul_server[count.index].id
    consul-server-ip-0 = ucloud_instance.consul_server[0].private_ip
    consul-server-ip-1 = ucloud_instance.consul_server[1].private_ip
    consul-server-ip-2 = ucloud_instance.consul_server[2].private_ip
  }
}

resource "null_resource" "install_consul_server" {
  count = local.instance_count
  depends_on = [
    ucloud_instance.consul_server,
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_eip.consul_servers[count.index].public_ip
    }
    inline = [
      data.template_file.setup-script[count.index].rendered,
      local.reconfig-ssh-keys-script,
    ]
  }
}

