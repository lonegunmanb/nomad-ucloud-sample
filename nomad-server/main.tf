resource "ucloud_instance" "nomad_servers" {
  count             = var.instance_count
  name              = "nomad-server-${var.group}-${count.index}"
  tag               = var.cluster_id
  availability_zone = var.az
  image_id          = var.image_id
  instance_type     = var.instance_type
  root_password     = var.root_password
  charge_type       = var.charge_type
  duration          = var.duration
  security_group    = var.sg_id
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  boot_disk_type    = var.local_disk_type
  data_disk_type    = var.local_disk_type
  data_disk_size    = var.use_udisk ? 0 : var.data_volume_size
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_disk" "data_disk" {
  count             = var.use_udisk && var.data_volume_size > 0 ? var.instance_count : 0
  name              = "nomad-server-${var.group}-${count.index}"
  availability_zone = var.az
  disk_type         = var.udisk_type
  disk_size         = var.data_volume_size
  charge_type       = var.charge_type
  duration          = var.duration
}

resource "ucloud_disk_attachment" "attachment" {
  count             = var.use_udisk && var.data_volume_size > 0 ? var.instance_count : 0
  availability_zone = var.az
  disk_id           = ucloud_disk.data_disk.*.id[count.index]
  instance_id       = ucloud_instance.nomad_servers.*.id[count.index]
}

resource "ucloud_eip" "nomad_servers" {
  count         = var.env_name != "test" ? 0 : var.instance_count
  name          = "nomad-server-${var.group}-${count.index}"
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = var.charge_type
  duration      = var.duration
  bandwidth     = 200
  tag           = var.cluster_id
}

resource "ucloud_eip_association" "nomad_ip" {
  count       = var.env_name != "test" ? 0 : var.instance_count
  eip_id      = ucloud_eip.nomad_servers.*.id[count.index]
  resource_id = ucloud_instance.nomad_servers.*.id[count.index]
}

locals {
  setup-script-path             = "${path.module}/setup.sh"
  reconfig-ssh-keys-script-path = "${path.module}/reconfig_ssh_keys.sh"
  reconfig-ssh-keys-script      = file(local.reconfig-ssh-keys-script-path)
}

data "external" "ipv6" {
  depends_on = [ucloud_instance.nomad_servers]
  count = var.env_name != "public" ? 0 : length(ucloud_instance.nomad_servers.*.id)
  program = ["python", "${path.module}/ipv6.py"]
  query = {
    url = var.ipv6_server_url
    resourceId = ucloud_instance.nomad_servers.*.id[count.index]
    regionId = var.region_id
  }
}

locals {
  server_ips = var.env_name == "test" ? ucloud_eip.nomad_servers.*.public_ip : (var.env_name == "public" ? [for map in data.external.ipv6.*.result: map["ip"]] : ucloud_instance.nomad_servers.*.private_ip)
}

data "template_file" "setup-script" {
  depends_on = [ucloud_instance.nomad_servers]
  count      = var.instance_count
  template   = file(local.setup-script-path)
  vars       = {
    region             = var.region
    az                 = var.az
    node-name          = ucloud_instance.nomad_servers[count.index].id
    instance-count     = var.instance_count
    consul-server-ip-0 = var.consul_server_ips[0]
    consul-server-ip-1 = var.consul_server_ips[1]
    consul-server-ip-2 = var.consul_server_ips[2]
  }
}

module "nomad_server_lb" {
  source               = "../internal_lb"
  instance_ids         = ucloud_instance.nomad_servers.*.id
  name                 = "nomadServerLb-${var.cluster_id}"
  ports                = var.nomad_port
  subnet_id            = var.subnet_id
  tag                  = var.cluster_id
  vpc_id               = var.vpc_id
  attachment_only      = true
  legacy_lb_id         = var.nomad_server_lb_id
  legacy_listener_id   = var.nomad_server_lb_listener_id
  legacy_lb_private_ip = var.nomad_server_lb_private_ip
}

resource "null_resource" "setup" {
  count      = var.instance_count
  depends_on = [
    ucloud_eip_association.nomad_ip,
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
      module.nomad_server_lb.setup_loopback_script,
      local.reconfig-ssh-keys-script,
      file("${path.module}/ensure_nomad_ready.sh")
    ]
  }
}

data "null_data_source" "finish_signal" {
  depends_on = [null_resource.setup]
  inputs = {
    signal = "finish"
  }
}
