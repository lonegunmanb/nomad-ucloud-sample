resource "ucloud_instance" "nomad_servers" {
  count = "${var.instance_count}"
  name = "nomad-server-${count.index}"
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

resource "ucloud_eip" "nomad_servers" {
  count = "${var.instance_count}"
  internet_type = "bgp"
  charge_mode = "traffic"
  charge_type = "dynamic"
  bandwidth = 200
  tag = "${var.cluster_id}"
}

resource "ucloud_eip_association" "nomad_ip" {
  count = "${var.instance_count}"
  eip_id = "${ucloud_eip.nomad_servers.*.id[count.index]}"
  resource_id = "${ucloud_instance.nomad_servers.*.id[count.index]}"
}


resource "ucloud_disk" "consul_data" {
  count = "${var.instance_count}"
  availability_zone = "${var.az[count.index%length(var.az)]}"
  name = "nomad-server-data-${count.index}"
  disk_size = "${var.data_volume_size}"
  tag = "${var.cluster_id}"
}

resource "ucloud_disk_attachment" "consul_server_data" {
  count = "${var.instance_count}"
  availability_zone = "${var.az[count.index%length(var.az)]}"
  disk_id = "${ucloud_disk.consul_data.*.id[count.index]}"
  instance_id = "${ucloud_instance.nomad_servers.*.id[count.index]}"
}

resource "null_resource" "setup" {
  count = "${var.instance_count}"
  depends_on = ["ucloud_eip_association.nomad_ip"]
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      password = "${var.root_password}"
      host = "${ucloud_eip.nomad_servers.*.public_ip[count.index]}"
    }
    inline = [
      "mkfs.ext4 /dev/vdb",
      "mount /dev/vdb /data",
      "echo 'mount /dev/vdb /data'>>/etc/rc.d/rc.local",
      "sed -i 's/SERVICE_DESCRIPTION/Consul Client/g' /etc/systemd/system/consul.service",
      "mkdir --parents /data/nomad",
      "sed -i 's/REGION/${var.region}/g' /etc/nomad.d/server.hcl",
      "sed -i 's/DATACENTER/${var.region}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/DATACENTER/${var.region}/g' /etc/nomad.d/server.hcl",
      "sed -i 's/NODENAME/${ucloud_instance.nomad_servers.*.id[count.index]}/g' /etc/nomad.d/server.hcl",
      "sed -i 's/EXPECTEDSVRS/${var.instance_count}/g' /etc/nomad.d/server.hcl",
      "sed -i 's/NODENAME/${ucloud_instance.nomad_servers.*.id[count.index]}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/CONSUL_SERVER1_IP/${var.consul_server_ips[0]}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/CONSUL_SERVER2_IP/${var.consul_server_ips[1]}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/CONSUL_SERVER3_IP/${var.consul_server_ips[2]}/g' /etc/consul.d/consul.hcl",
      "sed -i 's/SERVICE_DESCRIPTION/Nomad Server/g' /etc/systemd/system/nomad.service",
      "systemctl enable consul",
      "systemctl start consul",
      "systemctl enable nomad",
      "systemctl start nomad"
    ]
  }
}