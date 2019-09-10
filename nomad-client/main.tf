provider "ucloud" {
  region      = var.region
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  base_url    = var.ucloud_api_base_url
}

resource "ucloud_instance" "nomad_clients" {
  count             = var.instance_count
  name              = "nomad-client-${var.class}-${count.index}"
  tag               = var.cluster_id
  availability_zone = var.az[count.index % length(var.az)]
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
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_disk" "data_disk" {
  count             = var.use_udisk && var.data_volume_size>0 ? var.instance_count : 0
  name              = "nomad-${var.class}-data-${count.index}"
  availability_zone = var.az[count.index % length(var.az)]
  disk_type         = var.udisk_type
  disk_size         = var.data_volume_size
  charge_type       = var.charge_type
  duration          = var.duration
}

resource "ucloud_disk_attachment" "disk_attachment" {
  count             = var.use_udisk && var.data_volume_size>0 ? var.instance_count : 0
  availability_zone = var.az[count.index % length(var.az)]
  disk_id           = ucloud_disk.data_disk.*.id[count.index]
  instance_id       = ucloud_instance.nomad_clients.*.id[count.index]
}

resource "ucloud_eip" "nomad_clients" {
  count         = var.instance_count
  name          = "nomad-client-${var.cluster_id}-${var.class}-${count.index}"
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = var.charge_type
  duration      = var.duration
  bandwidth     = 200
  tag           = var.cluster_id
}

resource "ucloud_eip_association" "nomad_ip" {
  depends_on = [ucloud_instance.nomad_clients, ucloud_eip.nomad_clients]
  count       = var.instance_count
  eip_id      = ucloud_eip.nomad_clients.*.id[count.index]
  resource_id = ucloud_instance.nomad_clients.*.id[count.index]
}

locals {
  setup-script-path        = "${path.module}/setup.sh"
  reconfig-ssh-keys-script = file("${path.module}/reconfig_ssh_keys.sh")
}

module ipv6 {
  source         = "../ipv6"
  api_server_url = var.ipv6_server_url
  region_id      = var.region_id
  resourceIds    = ucloud_instance.nomad_clients.*.id
  disable        = var.env_name != "public"
}

locals {
  server_ips = var.env_name == "test" ? ucloud_eip.nomad_clients.*.public_ip : (var.env_name == "public" ? module.ipv6.ipv6s : ucloud_instance.nomad_clients.*.private_ip)
}

data "template_file" "setup-script" {
  depends_on = [ucloud_instance.nomad_clients]
  count      = var.instance_count
  template   = file(local.setup-script-path)
  vars       = {
    region             = var.region
    az                 = var.az[count.index % length(var.az)]
    node-name          = ucloud_instance.nomad_clients[count.index].id
    node-class         = var.class
    node-meta          = replace(
    <<EOF
                        meta {
                          az = \"${var.az[count.index % length(var.az)]}\"
                          eip = \"${ucloud_eip.nomad_clients.*.public_ip[count.index]}\"
                          hostIp = \"${ucloud_instance.nomad_clients.*.private_ip[count.index]}\"
                        }
EOF
    , "\n", "\\n")
    consul-server-ip-0 = var.consul_server_private_ips[0]
    consul-server-ip-1 = var.consul_server_private_ips[1]
    consul-server-ip-2 = var.consul_server_private_ips[2]
  }
}

resource "null_resource" "setup" {
  count      = var.instance_count
  depends_on = [
    ucloud_eip_association.nomad_ip,
    ucloud_disk_attachment.disk_attachment,
    ucloud_eip.nomad_clients,
    local.server_ips
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

data "null_data_source" "finish_signal" {
  depends_on = [null_resource.setup, ucloud_instance.nomad_clients]
  inputs = {
    signal = "finish"
  }
}