resource "ucloud_instance" "consul_server" {
  count = "${local.instance_count}"
  name = "consul-server-${count.index}"
  tag = "${var.cluster_id}"
  availability_zone = "${var.az[count.index%length(var.az)]}"
  image_id = "${var.image_id}"
  instance_type = "${var.instance_type}"
  root_password = "${var.root_password}"
  charge_type = "dynamic"
  security_group = "${var.sg_id}"
  vpc_id = "${var.vpc_id}"
  subnet_id = "${var.subnet_id}"
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_eip" "consul_servers" {
  count = "${local.instance_count}"
  internet_type = "bgp"
  charge_mode = "traffic"
  charge_type = "dynamic"
  bandwidth = 200
  tag = "${var.cluster_id}"
}

resource "ucloud_eip_association" "consul_ip" {
  count = "${local.instance_count}"
  eip_id = "${ucloud_eip.consul_servers.*.id[count.index]}"
  resource_id = "${ucloud_instance.consul_server.*.id[count.index]}"
}

resource "ucloud_disk" "consul_data" {
  count = "${local.instance_count}"
  availability_zone = "${var.az[count.index%length(var.az)]}"
  name = "consul-data-${count.index}"
  disk_size = "${var.data_volume_size}"
  tag = "${var.cluster_id}"
}

resource "ucloud_disk_attachment" "consul_server_data" {
  count = "${local.instance_count}"
  availability_zone = "${var.az[count.index%length(var.az)]}"
  disk_id = "${ucloud_disk.consul_data.*.id[count.index]}"
  instance_id = "${ucloud_instance.consul_server.*.id[count.index]}"
}

locals {
  setup-script-path = "${path.module}/setup.sh"
  reconfig-ssh-keys-script-path = "${path.module}/reconfig_ssh_keys.sh"
  reconfig-ssh-keys-script = "${file(local.reconfig-ssh-keys-script-path)}"
}

data "template_file" "setup-script" {
  count = "${local.instance_count}"
  template = "${file(local.setup-script-path)}"
  vars {
    region = "${var.region}"
    node-name = "${ucloud_instance.consul_server.*.id[count.index]}"
    consul-server-ip-0 = "${ucloud_instance.consul_server.*.private_ip[0]}"
    consul-server-ip-1 = "${ucloud_instance.consul_server.*.private_ip[1]}"
    consul-server-ip-2 = "${ucloud_instance.consul_server.*.private_ip[2]}"
  }
}

resource "null_resource" "install_consul_server" {
  count = "${local.instance_count}"
  depends_on = [
    "ucloud_instance.consul_server",
    "ucloud_disk_attachment.consul_server_data"]
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      password = "${var.root_password}"
      host = "${ucloud_eip.consul_servers.*.public_ip[count.index]}"
    }
    inline = [
      "${data.template_file.setup-script.*.rendered[count.index]}",
      "${local.reconfig-ssh-keys-script}"
    ]
  }
}