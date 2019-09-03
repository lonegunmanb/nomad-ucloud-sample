output projectId {
  value = var.project_id
}

output clientVpcId {
  value = data.terraform_remote_state.network.outputs.clientVpcId
}

output clientSubnetId {
  value = data.terraform_remote_state.network.outputs.clientSubnetId
}

output "cluster_id" {
  value = data.terraform_remote_state.network.outputs.cluster_id
}

output "region" {
  value = var.region
}

output "az" {
  value = var.az
}

output "consul_servers_public_ips" {
  value = module.consul_servers.public_ips
}

output "consul_servers_private_ips" {
  value = module.consul_servers.private_ips
}

module "consul_access_ipv6" {
  source = "./ipv6"
  disable = !var.provision_from_kun
  api_server_url = var.ipv6_server_url
  region_id = var.region_id
  resourceIds = [module.consul_servers.lb_id]
}

locals {
  nomad_server_ips  = var.provision_from_kun ? module.nomad_lb_ipv6.ipv6s : module.nomad_servers.public_ips
  consul_server_ips = var.provision_from_kun ? module.consul_access_ipv6.ipv6s : module.consul_servers.public_ips
  consul_access_ip  = length(local.consul_server_ips) > 0 ? local.consul_server_ips[0] : ""
  consul_access_url = length(local.consul_access_ip) > 15 ? "http://[${local.consul_access_ip}]:8500" : "http://${local.consul_access_ip}:8500"
}

output "consul_access_ip" {
  value = local.consul_access_ip
}

output "nomad_servers_ips" {
  value = module.nomad_servers.public_ips
}

module nomad_lb_ipv6 {
  source = "./ipv6"
  disable = !var.provision_from_kun
  api_server_url = var.ipv6_server_url
  region_id = var.region_id
  resourceIds = [module.nomad_servers.lb_id]
}

output "nomad_server_ip" {
  value = length(local.nomad_server_ips) > 0 ? local.nomad_server_ips[0] : ""
}

output "nomad_broker_public_ips" {
  value = module.broker.public_ips
}

output "nomad_broker_private_ips" {
  value = module.broker.private_ips
}

output "nomad_broker_ids" {
  value = module.broker.ids
}

output "nomad_namesvr_public_ips" {
  value = module.nameServer.public_ips
}

output "namesvr_private_ips" {
  value = module.nameServer.private_ips
}

output "namesvr_ids" {
  value = module.nameServer.ids
}

output "brokersvr_private_ips" {
  value = module.broker.private_ips
}

output "brokersvr_ids" {
  value = module.broker.ids
}

