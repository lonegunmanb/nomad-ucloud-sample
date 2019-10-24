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
  isolation_group   = var.isolation_group_id
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
  render-consul-config-path = "${path.module}/../scripts/render-consul-config.sh"
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

data "template_file" "consul-config" {
  depends_on = [
    ucloud_instance.nomad_servers
  ]
  count = var.instance_count
  template   = file(local.render-consul-config-path)
  vars       = {
    region             = var.region
    node-name          = ucloud_instance.nomad_servers[count.index].id
    consul-server-ip-0 = var.consul_server_ips[0]
    consul-server-ip-1 = var.consul_server_ips[1]
    consul-server-ip-2 = var.consul_server_ips[2]
  }
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
    cluster            = var.cluster_id
  }
}

data "template_file" "add-loopback-script" {
  template = file("${path.module}/add-loopback.sh.tplt")
  vars     = {
    vip    = var.nomad_server_lb_private_ip
    device = "lo:1"
  }
}

resource "ucloud_lb_attachment" "attachment" {
  count            = var.instance_count
  load_balancer_id = var.nomad_server_lb_id
  resource_id      = ucloud_instance.nomad_servers.*.id[count.index]
  port             = 4646
  listener_id      = var.nomad_server_4646_listener_id
}

//DO NOT MERGE THIS null_resource WITH setup, ROLLING UPDATE DEPENDENT ON THIS NAME
resource "null_resource" "config_consul" {
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
      file("${path.module}/../scripts/config-consul-agent.sh"),
      data.template_file.consul-config.*.rendered[count.index]
    ]
  }
}

resource "null_resource" "setup" {
  count      = var.instance_count
  depends_on = [
    null_resource.config_consul
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
      data.template_file.add-loopback-script.rendered,
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
