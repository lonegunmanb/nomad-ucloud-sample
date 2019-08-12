resource ucloud_isolation_group isolation_group {
  count = length(var.az)
  name = "nomad-client-${var.cluster_id}-${count.index}"
}

resource "ucloud_instance" "nomad_clients" {
  count             = var.instance_count
  name              = "nomad-client-${var.class}-${count.index}"
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
  isolation_group   = ucloud_isolation_group.isolation_group.*.id[count.index % length(var.az)]
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_eip" "nomad_clients" {
  count         = var.instance_count
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = "dynamic"
  bandwidth     = 200
  tag           = var.cluster_id
}

resource "ucloud_eip_association" "nomad_ip" {
  count       = var.instance_count
  eip_id      = ucloud_eip.nomad_clients[count.index].id
  resource_id = ucloud_instance.nomad_clients[count.index].id
}

locals {
  setup-script-path             = "${path.module}/setup.sh"
  reconfig-ssh-keys-script      = file("${path.module}/reconfig_ssh_keys.sh")
}

data "template_file" "build-terraform-plugin-cache-script" {
  template = file("${path.module}/../scripts/build-terraform-plugin-cache.sh")
  vars = {
    TF_PLUGIN_CONSUL_VERSION = var.TF_PLUGIN_CONSUL_VERSION
    TF_PLUGIN_NULL_VERSION = var.TF_PLUGIN_NULL_VERSION
    TF_PLUGIN_TEMPLATE_VERSION = var.TF_PLUGIN_TEMPLATE_VERSION
    TF_PLUGIN_UCLOUD_VERSION = var.TF_PLUGIN_UCLOUD_VERSION
  }
}

data "template_file" "setup-script" {
  count    = var.instance_count
  template = file(local.setup-script-path)
  vars = {
    region             = var.region
    az                 = var.az[count.index % length(var.az)]
    node-name          = ucloud_instance.nomad_clients[count.index].id
    node-class         = var.class
    node-meta          = "meta {\\naz=\"${var.az[count.index % length(var.az)]}\"\\n}"
    consul-server-ip-0 = var.consul_server_private_ips[0]
    consul-server-ip-1 = var.consul_server_private_ips[1]
    consul-server-ip-2 = var.consul_server_private_ips[2]
  }
}

resource "null_resource" "setup" {
  count = var.instance_count
  depends_on = [
    ucloud_eip_association.nomad_ip,
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_eip.nomad_clients[count.index].public_ip
    }
    inline = [
      data.template_file.setup-script[count.index].rendered,
      data.template_file.build-terraform-plugin-cache-script.rendered,
      local.reconfig-ssh-keys-script,
    ]
  }
}