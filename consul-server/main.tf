provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url    = var.ucloud_api_base_url
}

resource ucloud_isolation_group isolation_group {
  name = "consul-server-${var.cluster_id}"
}

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
  boot_disk_type    = var.local_disk_type
  data_disk_type    = var.local_disk_type
  data_disk_size    = var.use_udisk ? 0 : var.data_volume_size
  isolation_group   = ucloud_isolation_group.isolation_group.id
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_disk" "data_disk" {
  count             = var.use_udisk && var.data_volume_size > 0 ? local.instance_count : 0
  name              = "consul-server-data-${count.index}"
  availability_zone = var.az[count.index % length(var.az)]
  disk_size         = var.use_udisk ? var.data_volume_size : 0
  disk_type         = var.udisk_type
}

resource "ucloud_disk_attachment" "attachment" {
  count             = var.use_udisk && var.data_volume_size > 0 ? local.instance_count : 0
  availability_zone = var.az[count.index % length(var.az)]
  disk_id           = ucloud_disk.data_disk.*.id[count.index]
  instance_id       = ucloud_instance.consul_server.*.id[count.index]
}

resource "ucloud_eip" "consul_servers" {
  count         = var.provision_from_kun ? 0 : local.instance_count
  name          = "consul-server-${var.cluster_id}-${count.index}"
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = "dynamic"
  bandwidth     = 200
  tag           = var.cluster_id
}

resource "ucloud_eip_association" "consul_ip" {
  count       = var.provision_from_kun ? 0 : local.instance_count
  eip_id      = ucloud_eip.consul_servers[count.index].id
  resource_id = ucloud_instance.consul_server[count.index].id
}

locals {
  setup-script-path        = "${path.module}/setup.sh"
  reconfig-ssh-keys-script = file("${path.module}/reconfig_ssh_keys.sh")
}

module ipv6 {
  source         = "../ipv6"
  api_server_url = var.ipv6_server_url
  region_id      = var.region_id
  resourceIds    = ucloud_instance.consul_server.*.id
  disable        = !var.provision_from_kun
}

locals {
  server_ips = var.provision_from_kun ? module.ipv6.ipv6s : ucloud_eip.consul_servers.*.public_ip
}

data "template_file" "setup-script" {
  depends_on = [ucloud_instance.consul_server]
  count      = local.instance_count
  template   = file(local.setup-script-path)
  vars       = {
    region             = var.region
    node-name          = ucloud_instance.consul_server[count.index].id
    consul-server-ip-0 = ucloud_instance.consul_server[0].private_ip
    consul-server-ip-1 = ucloud_instance.consul_server[1].private_ip
    consul-server-ip-2 = ucloud_instance.consul_server[2].private_ip
  }
}

module "consulLb" {
  source       = "../internal_lb"
  tag          = var.cluster_id
  instance_ids = ucloud_instance.consul_server.*.id
  name         = "consulServer-${var.cluster_id}"
  ports        = [
    8500]
  subnet_id    = var.subnet_id
  vpc_id       = var.vpc_id
}

resource "null_resource" "install_consul_server" {
  count      = local.instance_count
  depends_on = [
    ucloud_instance.consul_server,
    ucloud_disk_attachment.attachment
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
      module.consulLb.setup_loopback_script,
      local.reconfig-ssh-keys-script,
    ]
  }
}