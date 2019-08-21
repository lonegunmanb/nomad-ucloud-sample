provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url    = var.ucloud_api_base_url
}

resource ucloud_security_group consul_server_sg {
  name = "rktmq-public-firewall-${local.cluster_id}"
  rules {
    port_range = "22"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = "accept"
  }

  //consul ui port
  rules {
    port_range = "8500"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = "accept"
  }

  //nomad ui port
  rules {
    port_range = "4646"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = "accept"
  }
  rules {
    port_range = "20000-32000"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = "accept"
  }
}

module consul_servers {
  source           = "./consul-server"
  region           = var.region
  instance_type    = var.consul_server_type
  image_id         = var.consul_server_image_id
  az               = var.az
  cluster_id       = local.cluster_id
  sg_id            = ucloud_security_group.consul_server_sg.id
  root_password    = var.consul_server_root_password
  vpc_id           = data.terraform_remote_state.network.outputs.mgrVpcId
  subnet_id        = data.terraform_remote_state.network.outputs.mgrSubnetId
  data_volume_size = 30
  ipv6_server_url = var.ipv6_server_url
  region_id = var.region_id
  provision_from_kun = var.provision_from_kun
  project_id = var.project_id
  ucloud_api_base_url = var.ucloud_api_base_url
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
}

module nomad_servers {
  source            = "./nomad-server"
  region            = var.region
  az                = var.az
  cluster_id        = local.cluster_id
  image_id          = var.nomad_server_image_id
  instance_count    = 3
  instance_type     = var.nomad_server_type
  root_password     = var.nomad_server_root_password
  sg_id             = ucloud_security_group.consul_server_sg.id
  vpc_id            = data.terraform_remote_state.network.outputs.mgrVpcId
  subnet_id         = data.terraform_remote_state.network.outputs.mgrSubnetId
  consul_server_ips = module.consul_servers.private_ips
  data_volume_size  = 30
  ipv6_server_url = var.ipv6_server_url
  region_id = var.region_id
  provision_from_kun = var.provision_from_kun
  project_id = var.project_id
  ucloud_api_base_url = var.ucloud_api_base_url
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
}

module nameServer {
  source                    = "./nomad-client"
  az                        = var.az
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  data_volume_size          = 30
  image_id                  = var.nomad_client_image_id
  instance_count            = 3
  instance_type             = var.nomad_client_namesvr_type
  region                    = var.region
  root_password             = var.nomad_client_root_password
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  consul_server_public_ips  = module.consul_servers.public_ips
  class                     = "nameServer"
  ipv6_server_url = var.ipv6_server_url
  region_id = var.region_id
  provision_from_kun = var.provision_from_kun
  project_id = var.project_id
  ucloud_api_base_url = var.ucloud_api_base_url
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
}

module broker {
  source                    = "./nomad-client"
  az                        = var.az
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  data_volume_size          = 30
  image_id                  = var.nomad_client_image_id
  instance_count            = 3
  instance_type             = var.nomad_client_broker_type
  region                    = var.region
  root_password             = var.nomad_client_root_password
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  consul_server_public_ips  = module.consul_servers.public_ips
  class                     = "broker"
  ipv6_server_url = var.ipv6_server_url
  region_id = var.region_id
  provision_from_kun = var.provision_from_kun
  project_id = var.project_id
  ucloud_api_base_url = var.ucloud_api_base_url
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
}

