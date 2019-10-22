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
  availability_zone = var.az[count.index]
  image_id          = var.image_id[count.index]
  instance_type     = var.instance_type[count.index]
  root_password     = var.root_password[count.index]
  charge_type       = var.charge_type[count.index]
  duration          = var.duration[count.index]
  security_group    = var.sg_id
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  boot_disk_type    = var.local_disk_type[count.index]
  data_disk_type    = var.local_disk_type[count.index]
  data_disk_size    = var.use_udisk[count.index] ? 0 : var.data_volume_size[count.index]
  isolation_group   = ucloud_isolation_group.isolation_group.id
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_disk" "data_disk0" {
  count             = var.use_udisk[0] && var.data_volume_size[0] > 0 ? 1 : 0
  name              = "consul-server-data-0"
  availability_zone = var.az[0]
  disk_size         = var.use_udisk[0] ? var.data_volume_size[0] : 0
  disk_type         = var.udisk_type[0]
  charge_type       = var.charge_type[0]
  duration          = var.duration[0]
}

resource "ucloud_disk" "data_disk1" {
  count             = var.use_udisk[1] && var.data_volume_size[1] > 0 ? 1 : 0
  name              = "consul-server-data-1"
  availability_zone = var.az[1]
  disk_size         = var.use_udisk[1] ? var.data_volume_size[1] : 0
  disk_type         = var.udisk_type[1]
  charge_type       = var.charge_type[1]
  duration          = var.duration[1]
}

resource "ucloud_disk" "data_disk2" {
  count             = var.use_udisk[2] && var.data_volume_size[2] > 0 ? 1 : 0
  name              = "consul-server-data-2"
  availability_zone = var.az[2]
  disk_size         = var.use_udisk[2] ? var.data_volume_size[2] : 0
  disk_type         = var.udisk_type[2]
  charge_type       = var.charge_type[2]
  duration          = var.duration[2]
}

resource "ucloud_disk_attachment" "attachment0" {
  count             = var.use_udisk[0] && var.data_volume_size[0] > 0 ? 1 : 0
  availability_zone = var.az[0]
  disk_id           = ucloud_disk.data_disk0.*.id[0]
  instance_id       = ucloud_instance.consul_server.*.id[0]
}

resource "ucloud_disk_attachment" "attachment1" {
  count             = var.use_udisk[1] && var.data_volume_size[1] > 0 ? 1 : 0
  availability_zone = var.az[1]
  disk_id           = ucloud_disk.data_disk1.*.id[0]
  instance_id       = ucloud_instance.consul_server.*.id[1]
}
resource "ucloud_disk_attachment" "attachment2" {
  count             = var.use_udisk[2] && var.data_volume_size[2] > 0 ? 1 : 0
  availability_zone = var.az[2]
  disk_id           = ucloud_disk.data_disk2.*.id[0]
  instance_id       = ucloud_instance.consul_server.*.id[2]
}

resource "ucloud_eip" "consul_servers" {
  count         = var.env_name != "test" ? 0 : local.instance_count
  name          = "consul-server-${var.cluster_id}-${count.index}"
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = var.charge_type[count.index]
  duration      = var.duration[count.index]
  bandwidth     = 200
  tag           = var.cluster_id
}

resource "ucloud_eip_association" "consul_ip" {
  count       = var.env_name != "test" ? 0 : local.instance_count
  eip_id      = ucloud_eip.consul_servers.*.id[count.index]
  resource_id = ucloud_instance.consul_server.*.id[count.index]
}

locals {
  config-consul-path       = "${path.module}/../scripts/render-consul-config.sh"
  setup-script-path        = "${path.module}/setup.sh"
}

data "external" "ipv6" {
  depends_on = [ucloud_instance.consul_server]
  count = var.env_name != "public" ? 0 : 3
  program = ["python", "${path.module}/ipv6.py"]
  query = {
    url = var.ipv6_server_url
    resourceId = ucloud_instance.consul_server.*.id[count.index]
    regionId = var.region_id
  }
}

locals {
  server_ips = var.env_name == "test" ? ucloud_eip.consul_servers.*.public_ip : (var.env_name == "public" ? [for map in data.external.ipv6.*.result: map["ip"]] : ucloud_instance.consul_server.*.private_ip)
}

data "template_file" "consul-config" {
  depends_on = [ucloud_instance.consul_server]
  count      = local.instance_count
  template   = file(local.config-consul-path)
  vars       = {
    region             = var.region
    node-name          = ucloud_instance.consul_server[count.index].id
    consul-server-ip-0 = ucloud_instance.consul_server[0].private_ip
    consul-server-ip-1 = ucloud_instance.consul_server[1].private_ip
    consul-server-ip-2 = ucloud_instance.consul_server[2].private_ip
  }
}

resource ucloud_lb intenalLb {
  name      = "consulServer-${var.cluster_id}"
  internal  = true
  tag       = var.cluster_id
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id
}

resource ucloud_lb_listener listener {
  load_balancer_id = ucloud_lb.intenalLb.id
  protocol         = "tcp"
  name             = "8500"
  port             = 8500
}

resource "ucloud_lb_attachment" "consul_attachment" {
  count            = local.instance_count
  listener_id      = ucloud_lb_listener.listener.id
  load_balancer_id = ucloud_lb.intenalLb.id
  resource_id      = ucloud_instance.consul_server.*.id[count.index]
  port             = 8500
}

data "template_file" "add-loopback-script" {
  template = file("${path.module}/add-loopback.sh.tplt")
  vars     = {
    vip    = ucloud_lb.intenalLb.private_ip
    device = "lo:1"
  }
}

resource "null_resource" "config_consul" {
  count      = local.instance_count
  depends_on = [
    ucloud_instance.consul_server,
    data.external.ipv6,
    ucloud_disk_attachment.attachment0,
    ucloud_disk_attachment.attachment1,
    ucloud_disk_attachment.attachment2
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password[count.index]
      host     = local.server_ips[count.index]
    }
    inline = [
      file("${path.module}/../scripts/consul-server.sh"),
      data.template_file.consul-config[count.index].rendered,
    ]
  }
}

resource "null_resource" "install_consul_server" {
  count      = local.instance_count
  depends_on = [
    null_resource.config_consul
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password[count.index]
      host     = local.server_ips[count.index]
    }
    inline = [
      file(local.setup-script-path),
      data.template_file.add-loopback-script.rendered,
      file("${path.module}/reconfig_ssh_keys.sh"),
    ]
  }
}

resource "null_resource" "ensure_consul_ready" {
  count      = local.instance_count
  depends_on = [
    ucloud_instance.consul_server,
    null_resource.install_consul_server
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password[count.index]
      host     = local.server_ips[count.index]
    }
    inline = [
      file("${path.module}/ensure_consul_ready.sh")
    ]
  }
}

data "null_data_source" "finish_signal" {
  depends_on = [null_resource.install_consul_server]
  inputs = {
    signal = "finish"
  }
}
