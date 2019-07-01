resource "ucloud_instance" "consul_server" {
  count = "${local.machine_count}"
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
}

resource "ucloud_eip" "consul_servers" {
  count = "${local.machine_count}"
  internet_type = "bgp"
  charge_mode = "traffic"
  charge_type = "dynamic"
  bandwidth = 200
  tag = "${var.cluster_id}"
}

resource "ucloud_eip_association" "consul_ip" {
  count = "${local.machine_count}"
  eip_id = "${ucloud_eip.consul_servers.*.id[count.index]}"
  resource_id = "${ucloud_instance.consul_server.*.id[count.index]}"
}

resource "ucloud_disk" "consul_data" {
  count = "${local.machine_count}"
  availability_zone = "${var.az[count.index%length(var.az)]}"
  name = "consul-data-${count.index}"
  disk_size = "${var.data_volume_size}"
  tag = "${var.cluster_id}"
}

resource "ucloud_disk_attachment" "consul_server_data" {
  count = "${local.machine_count}"
  availability_zone = "${var.az[count.index%length(var.az)]}"
  disk_id = "${ucloud_disk.consul_data.*.id[count.index]}"
  instance_id = "${ucloud_instance.consul_server.*.id[count.index]}"
}

resource "null_resource" "install_consul_server" {
  count = "${local.machine_count}"
  depends_on = ["ucloud_instance.consul_server"]
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      password = "${var.root_password}"
      host = "${ucloud_eip.consul_servers.*.public_ip[count.index]}"
    }
    inline = [
      "mkfs.ext4 /dev/vdb",
      "mount /dev/vdb /data",
      "echo 'mount /dev/vdb /data'>>/etc/rc.d/rc.local",
      "mkdir --parents /data/consul",
      "chown --recursive consul:consul /data/consul",
      "sed -i 's/SERVICE_DESCRIPTION/Consul Server/g' /etc/systemd/system/consul.service",
      "sed -i 's/DATACENTER/${var.region}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/NODENAME/${ucloud_instance.consul_server.*.id[count.index]}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/CONSUL_SERVER1_IP/${ucloud_instance.consul_server.*.private_ip[0]}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/CONSUL_SERVER2_IP/${ucloud_instance.consul_server.*.private_ip[1]}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/CONSUL_SERVER3_IP/${ucloud_instance.consul_server.*.private_ip[2]}/g' /etc/consul.d/consul.hcl",
      "systemctl enable consul",
      "systemctl start consul",
    ]
  }
}