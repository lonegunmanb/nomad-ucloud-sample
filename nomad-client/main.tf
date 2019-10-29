resource "ucloud_isolation_group" "nomad_clients_isolation_group" {
  count = floor((var.instance_count - 1) / 7) + 1
  name = "${var.class}-${var.group}-${count.index}"
}

resource "ucloud_instance" "nomad_clients" {
  count             = var.instance_count
  name              = "${format("%04d", count.index)}-nomad-client-${var.cluster_id}-${var.class}-${var.group}"
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
  boot_disk_type    = var.use_udisk ? (var.udisk_type == "rssd_data_disk" ? "cloud_ssd" : "local_ssd") : var.local_disk_type
  data_disk_type    = var.local_disk_type
  data_disk_size    = var.use_udisk ? 0 : var.data_volume_size
  remark            = var.az
  isolation_group   = ucloud_isolation_group.nomad_clients_isolation_group.*.id[floor(count.index / 7)]
  provisioner "local-exec" {
    command = "sleep 10"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "ucloud_disk" "data_disk" {
  count             = var.use_udisk && var.data_volume_size>0 ? var.instance_count : 0
  name              = "${format("%04d", count.index)}-nomad-${var.cluster_id}-${var.class}-${var.group}"
  availability_zone = var.az
  disk_type         = var.udisk_type
  disk_size         = var.data_volume_size
  charge_type       = var.charge_type
  duration          = var.duration
  lifecycle {
    create_before_destroy = true
  }
}

resource "ucloud_disk_attachment" "disk_attachment" {
  count             = var.use_udisk && var.data_volume_size>0 ? var.instance_count : 0
  availability_zone = var.az
  disk_id           = ucloud_disk.data_disk.*.id[count.index]
  instance_id       = ucloud_instance.nomad_clients.*.id[count.index]
  lifecycle {
    create_before_destroy = true
  }
}

resource "ucloud_eip" "nomad_clients" {
  count         = var.env_name == "test" ? var.instance_count : 0
  name          = "${format("%04d", count.index)}-nomad-client-${var.cluster_id}-${var.class}-${var.group}"
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = var.charge_type
  duration      = var.duration
  bandwidth     = 200
  tag           = var.cluster_id
  lifecycle {
    create_before_destroy = true
  }
}

resource "ucloud_eip_association" "nomad_ip" {
  depends_on  = [
    ucloud_instance.nomad_clients,
    ucloud_eip.nomad_clients]
  count       = var.env_name == "test" ? var.instance_count : 0
  eip_id      = ucloud_eip.nomad_clients.*.id[count.index]
  resource_id = ucloud_instance.nomad_clients.*.id[count.index]
  lifecycle {
    create_before_destroy = true
  }
}

locals {
  render-consul-config-path = "${path.module}/../scripts/render-consul-config.sh"
  setup-script-path        = "${path.module}/setup.sh"
  reconfig-ssh-keys-script = file("${path.module}/reconfig_ssh_keys.sh")
}

data "external" "ipv6" {
  depends_on = [
    ucloud_instance.nomad_clients]
  count      = var.env_name != "public" ? 0 : length(ucloud_instance.nomad_clients.*.id)
  program    = [
    "python",
    "${path.module}/ipv6.py"]
  query      = {
    url        = var.ipv6_server_url
    resourceId = ucloud_instance.nomad_clients.*.id[count.index]
    regionId   = var.region_id
  }
}

locals {
  server_ips = var.env_name == "test" ? ucloud_eip.nomad_clients.*.public_ip : (var.env_name == "public" ? [for map in data.external.ipv6.*.result: map["ip"]] : ucloud_instance.nomad_clients.*.private_ip)
}

data "template_file" "consul-config" {
  depends_on = [
    ucloud_instance.nomad_clients
  ]
  count = var.instance_count
  template   = file(local.render-consul-config-path)
  vars       = {
    region             = var.region
    node-name          = ucloud_instance.nomad_clients[count.index].id
    consul-server-ip-0 = var.consul_server_private_ips[0]
    consul-server-ip-1 = var.consul_server_private_ips[1]
    consul-server-ip-2 = var.consul_server_private_ips[2]
  }
}

data "template_file" "setup-script" {
  depends_on = [
    ucloud_instance.nomad_clients]
  count      = var.instance_count
  template   = file(local.setup-script-path)
  vars       = {
    region             = var.region
    az                 = var.az
    node-name          = ucloud_instance.nomad_clients[count.index].id
    node-class         = var.class
    node-meta          = replace(
    <<EOF
                        meta {
                          az = \"${var.az}\"
                          eip = \"${length(ucloud_eip.nomad_clients.*.public_ip) > 0 ? ucloud_eip.nomad_clients.*.public_ip[count.index] : ""}\"
                          hostIp = \"${ucloud_instance.nomad_clients.*.private_ip[count.index]}\"
                        }
EOF
    , "\n", "\\n")
    cluster           = var.cluster_id
  }
}

//DO NOT MERGE THIS null_resource WITH setup, ROLLING UPDATE DEPENDENT ON THIS NAME
resource "null_resource" "config_consul" {
  count = var.instance_count
  depends_on = [
    ucloud_eip_association.nomad_ip,
    ucloud_disk_attachment.disk_attachment,
    ucloud_eip.nomad_clients,
    data.external.ipv6
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
  lifecycle {
    create_before_destroy = true
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
      local.reconfig-ssh-keys-script,
    ]
  }
  lifecycle {
    create_before_destroy = true
  }
}

data "null_data_source" "finish_signal" {
  depends_on = [
    null_resource.setup,
    ucloud_instance.nomad_clients]
  inputs     = {
    signal = "finish"
  }
}
