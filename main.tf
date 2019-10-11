provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url    = var.ucloud_api_base_url
}

resource ucloud_security_group consul_server_sg {
  name = "rktmq-public-firewall-${local.cluster_id}"
  tag  = local.cluster_id
  rules {
    port_range = "22"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = var.env_name != "test" ? "drop" : "accept"
  }

  //consul ui port
  rules {
    port_range = "8500"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = var.env_name != "test" ? "drop" : "accept"
  }

  //nomad ui port
  rules {
    port_range = "4646"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = var.env_name != "test" ? "drop" : "accept"
  }
  //namesvr index fabio port
  rules {
    port_range = var.namesvr_http_endpoint_port
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = var.env_name != "test" ? "drop" : "accept"
  }
  //prometheus port
  rules {
    port_range = var.prometheus_port
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = var.env_name != "test" ? "drop" : "accept"
  }
  rules {
    port_range = "20000-32000"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = var.env_name == "private" ? "drop" : "accept"
  }
}

module consul_servers {
  source              = "./consul-server"
  region              = var.region
  instance_type       = local.consul_server_type
  image_id            = local.consul_server_image_id
  az                  = local.az
  cluster_id          = local.cluster_id
  sg_id               = ucloud_security_group.consul_server_sg.id
  root_password       = local.consul_server_root_password
  vpc_id              = data.terraform_remote_state.network.outputs.mgrVpcId
  subnet_id           = data.terraform_remote_state.network.outputs.mgrSubnetId
  use_udisk           = local.consul_server_use_udisk
  local_disk_type     = local.consul_server_local_disk_type
  udisk_type          = local.consul_server_udisk_type
  data_volume_size    = local.consul_server_data_disk_size
  ipv6_server_url     = var.ipv6_server_url
  region_id           = var.region_id
  env_name            = var.env_name
  project_id          = var.project_id
  ucloud_api_base_url = var.ucloud_api_base_url
  ucloud_pub_key      = var.ucloud_pub_key
  ucloud_secret       = var.ucloud_secret
  charge_type         = local.consul_server_charge_type
  duration            = local.consul_server_charge_duration
}

locals {
  mgr_vpc_id    = data.terraform_remote_state.network.outputs.mgrVpcId
  mgr_subnet_id = data.terraform_remote_state.network.outputs.mgrSubnetId
}

resource ucloud_lb nomad_server_lb {
  name      = "nomadServerLb-${local.cluster_id}"
  internal  = true
  tag       = local.cluster_id
  vpc_id    = local.mgr_vpc_id
  subnet_id = local.mgr_subnet_id
}

locals {
  nomad_port = 4646
}

resource ucloud_lb_listener nomad_server_4646_listener {
  load_balancer_id = ucloud_lb.nomad_server_lb.id
  protocol = "tcp"
  name = "nomad_4646"
  port = local.nomad_port
}

module nomad_server0 {
  source                      = "./nomad-server"
  region                      = var.region
  az                          = local.az[0]
  cluster_id                  = local.cluster_id
  image_id                    = local.nomad_server_image_id[0]
  instance_count              = local.nomad_server_count[0]
  instance_type               = local.nomad_server_type[0]
  root_password               = local.nomad_server_root_password[0]
  sg_id                       = ucloud_security_group.consul_server_sg.id
  vpc_id                      = data.terraform_remote_state.network.outputs.mgrVpcId
  subnet_id                   = data.terraform_remote_state.network.outputs.mgrSubnetId
  consul_server_ips           = module.consul_servers.private_ips
  use_udisk                   = local.nomad_server_use_udisk[0]
  local_disk_type             = local.nomad_server_local_disk_type[0]
  udisk_type                  = local.nomad_server_udisk_type[0]
  data_volume_size            = local.nomad_server_data_disk_size[0]
  ipv6_server_url             = var.ipv6_server_url
  region_id                   = var.region_id
  env_name                    = var.env_name
  charge_type                 = local.nomad_server_charge_type[0]
  duration                    = local.nomad_server_charge_duration[0]
  group                       = "${local.az[0]}-0"
  nomad_server_lb_id          = ucloud_lb.nomad_server_lb.id
  nomad_server_4646_listener_id = ucloud_lb_listener.nomad_server_4646_listener.id
  nomad_server_lb_private_ip  = ucloud_lb.nomad_server_lb.private_ip
}

module nomad_server1 {
  source                      = "./nomad-server"
  region                      = var.region
  az                          = local.az[1]
  cluster_id                  = local.cluster_id
  image_id                    = local.nomad_server_image_id[1]
  instance_count              = local.nomad_server_count[1]
  instance_type               = local.nomad_server_type[1]
  root_password               = local.nomad_server_root_password[1]
  sg_id                       = ucloud_security_group.consul_server_sg.id
  vpc_id                      = data.terraform_remote_state.network.outputs.mgrVpcId
  subnet_id                   = data.terraform_remote_state.network.outputs.mgrSubnetId
  consul_server_ips           = module.consul_servers.private_ips
  use_udisk                   = local.nomad_server_use_udisk[1]
  local_disk_type             = local.nomad_server_local_disk_type[1]
  udisk_type                  = local.nomad_server_udisk_type[1]
  data_volume_size            = local.nomad_server_data_disk_size[1]
  ipv6_server_url             = var.ipv6_server_url
  region_id                   = var.region_id
  env_name                    = var.env_name
  charge_type                 = local.nomad_server_charge_type[1]
  duration                    = local.nomad_server_charge_duration[1]
  group                       = "${local.az[1]}-1"
  nomad_server_lb_id          = ucloud_lb.nomad_server_lb.id
  nomad_server_4646_listener_id = ucloud_lb_listener.nomad_server_4646_listener.id
  nomad_server_lb_private_ip  = ucloud_lb.nomad_server_lb.private_ip
}

module nomad_server2 {
  source                      = "./nomad-server"
  region                      = var.region
  az                          = local.az[2]
  cluster_id                  = local.cluster_id
  image_id                    = local.nomad_server_image_id[2]
  instance_count              = local.nomad_server_count[2]
  instance_type               = local.nomad_server_type[2]
  root_password               = local.nomad_server_root_password[2]
  sg_id                       = ucloud_security_group.consul_server_sg.id
  vpc_id                      = data.terraform_remote_state.network.outputs.mgrVpcId
  subnet_id                   = data.terraform_remote_state.network.outputs.mgrSubnetId
  consul_server_ips           = module.consul_servers.private_ips
  use_udisk                   = local.nomad_server_use_udisk[2]
  local_disk_type             = local.nomad_server_local_disk_type[2]
  udisk_type                  = local.nomad_server_udisk_type[2]
  data_volume_size            = local.nomad_server_data_disk_size[2]
  ipv6_server_url             = var.ipv6_server_url
  region_id                   = var.region_id
  env_name                    = var.env_name
  charge_type                 = local.nomad_server_charge_type[2]
  duration                    = local.nomad_server_charge_duration[2]
  group                       = "${local.az[2]}-2"
  nomad_server_lb_id          = ucloud_lb.nomad_server_lb.id
  nomad_server_4646_listener_id = ucloud_lb_listener.nomad_server_4646_listener.id
  nomad_server_lb_private_ip  = ucloud_lb.nomad_server_lb.private_ip
}

locals {
  nameServerIdFile = "./nameServerId"
  nomad_client_broker_image_id = length(var.nomad_client_broker_image_id) == 1 ? [for i in range(3): var.nomad_client_broker_image_id[0]] : var.nomad_client_broker_image_id
  nomad_client_namesvr_image_id = length(var.nomad_client_namesvr_image_id) == 1 ? [for i in range(3): var.nomad_client_namesvr_image_id[0]] : var.nomad_client_namesvr_image_id
  namesvr_instance_type = length(var.nomad_client_namesvr_type) == 1 ? [for i in range(3): var.nomad_client_namesvr_type[0]] : var.nomad_client_namesvr_type
  broker_instance_type = length(var.nomad_client_broker_type) == 1 ? [for i in range(3): var.nomad_client_broker_type[0]] : var.nomad_client_broker_type
  client_broker_root_password = length(var.nomad_client_broker_root_password) == 1 ? [for i in range(3): var.nomad_client_broker_root_password[0]] : var.nomad_client_broker_root_password
  client_namesvr_root_password = length(var.nomad_client_namesvr_root_password) == 1 ? [for i in range(3): var.nomad_client_namesvr_root_password[0]] : var.nomad_client_namesvr_root_password
}

module nameServer0 {
  source                    = "./nomad-client"
  az                        = local.az[0]
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  use_udisk                 = local.name_server_use_udisk[0]
  local_disk_type           = local.name_server_local_disk_type[0]
  udisk_type                = local.name_server_udisk_type[0]
  data_volume_size          = local.name_server_data_disk_size[0]
  image_id                  = local.nomad_client_namesvr_image_id[0]
  instance_count            = var.name_server_count[0]
  instance_type             = local.namesvr_instance_type[0]
  region                    = var.region
  root_password             = local.client_namesvr_root_password[0]
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  class                     = "nameServer"
  ipv6_server_url           = var.ipv6_server_url
  region_id                 = var.region_id
  env_name                  = var.env_name
  consul_access_url         = local.consul_access_url
  charge_type               = local.client_charge_type[0]
  duration                  = local.client_charge_duration[0]
  group                     = "${local.az[0]}-0"
}

module nameServer1 {
  source                    = "./nomad-client"
  az                        = local.az[1]
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  use_udisk                 = local.name_server_use_udisk[1]
  local_disk_type           = local.name_server_local_disk_type[1]
  udisk_type                = local.name_server_udisk_type[1]
  data_volume_size          = local.name_server_data_disk_size[1]
  image_id                  = local.nomad_client_namesvr_image_id[1]
  instance_count            = var.name_server_count[1]
  instance_type             = local.namesvr_instance_type[1]
  region                    = var.region
  root_password             = local.client_namesvr_root_password[1]
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  class                     = "nameServer"
  ipv6_server_url           = var.ipv6_server_url
  region_id                 = var.region_id
  env_name                  = var.env_name
  consul_access_url         = local.consul_access_url
  charge_type               = local.client_charge_type[1]
  duration                  = local.client_charge_duration[1]
  group                     = "${local.az[1]}-1"
}

module nameServer2 {
  source                    = "./nomad-client"
  az                        = local.az[2]
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  use_udisk                 = local.name_server_use_udisk[2]
  local_disk_type           = local.name_server_local_disk_type[2]
  udisk_type                = local.name_server_udisk_type[2]
  data_volume_size          = local.name_server_data_disk_size[2]
  image_id                  = local.nomad_client_namesvr_image_id[2]
  instance_count            = var.name_server_count[2]
  instance_type             = local.namesvr_instance_type[2]
  region                    = var.region
  root_password             = local.client_namesvr_root_password[2]
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  class                     = "nameServer"
  ipv6_server_url           = var.ipv6_server_url
  region_id                 = var.region_id
  env_name                  = var.env_name
  consul_access_url         = local.consul_access_url
  charge_type               = local.client_charge_type[2]
  duration                  = local.client_charge_duration[2]
  group                     = "${local.az[2]}-2"
}

module broker0 {
  source                    = "./nomad-client"
  az                        = local.az[0]
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  use_udisk                 = local.broker_use_udisk[0]
  local_disk_type           = local.broker_local_disk_type[0]
  udisk_type                = local.broker_udisk_type[0]
  data_volume_size          = local.broker_data_disk_size[0]
  image_id                  = local.nomad_client_broker_image_id[0]
  instance_count            = var.broker_count[0]
  instance_type             = local.broker_instance_type[0]
  region                    = var.region
  root_password             = local.client_broker_root_password[0]
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  class                     = "broker"
  ipv6_server_url           = var.ipv6_server_url
  region_id                 = var.region_id
  env_name                  = var.env_name
  consul_access_url         = local.consul_access_url
  charge_type               = local.client_charge_type[0]
  duration                  = local.client_charge_duration[0]
  group                     = "${local.az[0]}-0"
}

module broker1 {
  source                    = "./nomad-client"
  az                        = var.az[1]
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  use_udisk                 = local.broker_use_udisk[1]
  local_disk_type           = local.broker_local_disk_type[1]
  udisk_type                = local.broker_udisk_type[1]
  data_volume_size          = local.broker_data_disk_size[1]
  image_id                  = local.nomad_client_broker_image_id[1]
  instance_count            = var.broker_count[1]
  instance_type             = local.broker_instance_type[1]
  region                    = var.region
  root_password             = local.client_broker_root_password[1]
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  class                     = "broker"
  ipv6_server_url           = var.ipv6_server_url
  region_id                 = var.region_id
  env_name                  = var.env_name
  consul_access_url         = local.consul_access_url
  charge_type               = local.client_charge_type[1]
  duration                  = local.client_charge_duration[1]
  group                     = "${local.az[1]}-1"
}

module broker2 {
  source                    = "./nomad-client"
  az                        = var.az[2]
  cluster_id                = local.cluster_id
  consul_server_private_ips = module.consul_servers.private_ips
  use_udisk                 = local.broker_use_udisk[2]
  local_disk_type           = local.broker_local_disk_type[2]
  udisk_type                = local.broker_udisk_type[2]
  data_volume_size          = local.broker_data_disk_size[2]
  image_id                  = local.nomad_client_broker_image_id[2]
  instance_count            = var.broker_count[2]
  instance_type             = local.broker_instance_type[2]
  region                    = var.region
  root_password             = local.client_broker_root_password[2]
  sg_id                     = ucloud_security_group.consul_server_sg.id
  vpc_id                    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id                 = data.terraform_remote_state.network.outputs.clientSubnetId
  class                     = "broker"
  ipv6_server_url           = var.ipv6_server_url
  region_id                 = var.region_id
  env_name                  = var.env_name
  consul_access_url         = local.consul_access_url
  charge_type               = local.client_charge_type[2]
  duration                  = local.client_charge_duration[2]
  group                     = "${local.az[2]}-2"
}

module "nameServerid0" {
  source = "./module_variables"
  file_name = "nameServerid0"
  input  = module.nameServer0.ids
}

module "nameServerid1" {
  source = "./module_variables"
  file_name = "nameServerid1"
  input  = module.nameServer1.ids
}

module "nameServerid2" {
  source = "./module_variables"
  file_name = "nameServerid2"
  input  = module.nameServer2.ids
}

locals {
  nameServerExposePots = [var.namesvr_http_endpoint_port, var.prometheus_port]
  total_name_server_count = length(flatten([for i in var.name_server_count:range(i)]))
}

resource ucloud_lb name_server_internal_lb {
  name      = "nameServerInternalLb-${local.cluster_id}"
  internal  = true
  tag       = local.cluster_id
  vpc_id    = data.terraform_remote_state.network.outputs.clientVpcId
  subnet_id = data.terraform_remote_state.network.outputs.clientSubnetId
}

resource ucloud_lb_listener namesvr_index_listener {
  load_balancer_id = ucloud_lb.name_server_internal_lb.id
  protocol         = "tcp"
  name             = var.namesvr_http_endpoint_port
  port             = var.namesvr_http_endpoint_port
}

resource ucloud_lb_listener namesvr_prometheus_listener {
  load_balancer_id = ucloud_lb.name_server_internal_lb.id
  protocol         = "tcp"
  name             = var.prometheus_port
  port             = var.prometheus_port
}

module "nameServerInternalLb0" {
  source       = "./internal_lb"
  instance_ids = module.nameServerid0.output
  attachment_count = var.name_server_count[0] * length(local.nameServerExposePots)
  name         = "nameServerInternalLb-${local.cluster_id}"
  ports        = local.nameServerExposePots
  vpc_id       = ""
  subnet_id    = ""
  tag          = local.cluster_id
  attachment_only = true
  legacy_lb_id = ucloud_lb.name_server_internal_lb.id
  legacy_listener_id = [ucloud_lb_listener.namesvr_index_listener.id, ucloud_lb_listener.namesvr_prometheus_listener.id]
  legacy_lb_private_ip = ucloud_lb.name_server_internal_lb.private_ip
}

module "nameServerInternalLb1" {
  source       = "./internal_lb"
  instance_ids = module.nameServerid1.output
  attachment_count = var.name_server_count[1] * length(local.nameServerExposePots)
  name         = "nameServerInternalLb-${local.cluster_id}"
  ports        = local.nameServerExposePots
  vpc_id       = ""
  subnet_id    = ""
  tag          = local.cluster_id
  attachment_only = true
  legacy_lb_id = ucloud_lb.name_server_internal_lb.id
  legacy_listener_id = [ucloud_lb_listener.namesvr_index_listener.id, ucloud_lb_listener.namesvr_prometheus_listener.id]
  legacy_lb_private_ip = ucloud_lb.name_server_internal_lb.private_ip
}

module "nameServerInternalLb2" {
  source       = "./internal_lb"
  instance_ids = module.nameServerid2.output
  attachment_count = var.name_server_count[2] * length(local.nameServerExposePots)
  name         = "nameServerInternalLb-${local.cluster_id}"
  ports        = local.nameServerExposePots
  vpc_id       = ""
  subnet_id    = ""
  tag          = local.cluster_id
  attachment_only = true
  legacy_lb_id = ucloud_lb.name_server_internal_lb.id
  legacy_listener_id = [ucloud_lb_listener.namesvr_index_listener.id, ucloud_lb_listener.namesvr_prometheus_listener.id]
  legacy_lb_private_ip = ucloud_lb.name_server_internal_lb.private_ip
}

locals {
  nameServerSshIp = concat(module.nameServer0.ssh_ip, module.nameServer1.ssh_ip, module.nameServer2.ssh_ip)
  nameServerRootPasswords = concat([for i in range(var.name_server_count[0]):local.client_broker_root_password[0]], [for i in range(var.name_server_count[1]):local.client_broker_root_password[1]], [for i in range(var.name_server_count[2]):local.client_broker_root_password[2]])
}

resource "null_resource" "setup_loopback_for_internal_lb" {
  depends_on = [module.nameServer0.finish_signal]
  count = var.name_server_count[0] + var.name_server_count[1] + var.name_server_count[2]
  triggers = {
    ip = local.nameServerSshIp[count.index]
  }
  provisioner "remote-exec" {
      connection {
        type     = "ssh"
        user     = "root"
        password = local.nameServerRootPasswords[count.index]
        host     = local.nameServerSshIp[count.index]
      }
    inline = [
      module.nameServerInternalLb0.setup_loopback_script
    ]
  }
}
