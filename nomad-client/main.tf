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

module ipv6 {
  source = "../ipv6"
  api_server_url = var.ipv6_server_url
  region_id = var.region_id
  resourceIds = ucloud_instance.nomad_clients.*.id
  disable = !var.provision_from_kun
}

locals {
  server_ips = var.provision_from_kun ? module.ipv6.ipv6s : ucloud_eip.nomad_clients.*.public_ip
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
    ucloud_eip_association.nomad_ip
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = local.server_ips[count.index]
    }
    inline = [
      data.template_file.setup-script[count.index].rendered,
      local.reconfig-ssh-keys-script,
    ]
  }
}