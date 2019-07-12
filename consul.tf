provider "ucloud" {
  public_key = "${var.ucloud_pub_key}"
  private_key = "${var.ucloud_secret}"
  project_id = "${var.project_id}"
  region = "${var.region}"
}

data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "./network/terraform.tfstate"
  }
}

locals {
  cluster_id = "${data.terraform_remote_state.network.cluster_id}"
}

resource "ucloud_security_group" "consul_server_sg" {
  rules {
    port_range = "22"
    protocol = "tcp"
    cidr_block = "${var.allow_ip}"
    policy = "accept"
  }
  //consul ui port
  rules {
    port_range = "8500"
    protocol = "tcp"
    cidr_block = "${var.allow_ip}"
    policy = "accept"
  }
  //nomad ui port
  rules {
    port_range = "4646"
    protocol = "tcp"
    cidr_block = "${var.allow_ip}"
    policy = "accept"
  }
  rules {
    port_range = "20000-60000"
    protocol = "tcp"
    cidr_block = "${var.allow_ip}"
    policy = "accept"
  }
}

module "consul_servers" {
  source = "./consul-server"
  region = "${var.region}"
  instance_type = "${var.consul_server_type}"
  image_id = "${var.consul_server_image_id}"
  az = "${var.az}"
  cluster_id = "${local.cluster_id}"
  sg_id = "${ucloud_security_group.consul_server_sg.id}"
  root_password = "${var.consul_server_root_password}"
  vpc_id = "${data.terraform_remote_state.network.vpc_id}"
  subnet_id = "${data.terraform_remote_state.network.consul_subnet_id}"
  data_volume_size = 30
}

module "nomad_servers" {
  source = "./nomad-server"
  region = "${var.region}"
  az = "${var.az}"
  cluster_id = "${local.cluster_id}"
  image_id = "${var.nomad_server_image_id}"
  instance_count = 3
  instance_type = "${var.nomad_server_type}"
  root_password = "${var.nomad_server_root_password}"
  sg_id = "${ucloud_security_group.consul_server_sg.id}"
  vpc_id = "${data.terraform_remote_state.network.vpc_id}"
  subnet_id = "${data.terraform_remote_state.network.nomad_subnet_id}"
  consul_server_ips = "${module.consul_servers.consul_server_private_ips}"
  data_volume_size = 30
}

module "nomad_clients" {
  source = "./nomad-client"
  az = "${var.az}"
  cluster_id = "${local.cluster_id}"
  consul_server_private_ips = "${module.consul_servers.consul_server_private_ips}"
  data_volume_size = 30
  image_id = "${var.nomad_client_image_id}"
  instance_count = 3
  instance_type = "${var.nomad_client_type}"
  region = "${var.region}"
  root_password = "${var.nomad_client_root_password}"
  sg_id = "${ucloud_security_group.consul_server_sg.id}"
  subnet_id = "${data.terraform_remote_state.network.nomad_subnet_id}"
  vpc_id = "${data.terraform_remote_state.network.vpc_id}"
  consul_server_public_ips = "${module.consul_servers.public_ips}"
}