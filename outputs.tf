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
  value = local.az
}

output "consul_servers_public_ips" {
  value = module.consul_servers.public_ips
}

output "consul_servers_private_ips" {
  value = module.consul_servers.private_ips
}

module "consul_access_ipv6" {
  source = "./ipv6"
  disable = var.env_name != "public"
  api_server_url = var.ipv6_server_url
  region_id = var.region_id
  resourceIds = [module.consul_servers.lb_id]
}

locals {
  nomad_server_public_ips = concat(module.nomad_server0.public_ips, module.nomad_server1.public_ips, module.nomad_server2.public_ips)
  nomad_server_ssh_ips = concat(module.nomad_server0.ssh_ip, module.nomad_server1.ssh_ip, module.nomad_server2.ssh_ip)
  nomad_server_ips  = var.env_name == "test" ? local.nomad_server_public_ips : module.nomad_lb_ipv6.ipv6s
  nomad_server_access_ip = var.env_name == "test" ? (length(local.nomad_server_ips) > 0 ? local.nomad_server_ips[0] : "") : (module.nomad_lb_ipv6.ipv6s[0])
  consul_server_ips = var.env_name == "test" ? module.consul_servers.public_ips : (var.env_name == "public" ? module.consul_access_ipv6.ipv6s : module.consul_servers.private_ips)
  consul_access_ip  = length(local.consul_server_ips) > 0 ? local.consul_server_ips[0] : ""
  consul_access_url = length(local.consul_access_ip) > 15 ? "http://[${local.consul_access_ip}]:8500" : "http://${local.consul_access_ip}:8500"
}

output "consul_access_ip" {
  value = local.consul_access_ip
}

output "consul_lb_ip" {
  value = module.consul_servers.lb_ip
}

output "nomad_servers_ips" {
  value = local.nomad_server_public_ips
}

module nomad_lb_ipv6 {
  source = "./ipv6"
  disable = var.env_name != "public"
  api_server_url = var.ipv6_server_url
  region_id = var.region_id
  resourceIds = [ucloud_lb.nomad_server_lb.id]
}

output "nomad_server_ip" {
  value = length(local.nomad_server_ips) > 0 ? local.nomad_server_ips[0] : ""
}

output "nomad_server_access_url" {
  value = length(local.nomad_server_access_ip) > 15 ? "http://[${local.nomad_server_access_ip}]:4646" : "http://${local.nomad_server_access_ip}:4646"
}

output "nomad_broker_ssh_ips" {
  value = concat(module.broker0.ssh_ip, module.broker1.ssh_ip, module.broker2.ssh_ip)
}

output "nomad_broker_ssh_ip_array" {
  value = [module.broker0.ssh_ip, module.broker1.ssh_ip, module.broker2.ssh_ip]
}

output "nomad_broker_public_ips" {
  value = concat(module.broker0.public_ips, module.broker1.public_ips, module.broker2.public_ips)
}

output "nomad_broker_private_ips" {
  value = concat(module.broker0.private_ips, module.broker1.private_ips, module.broker2.private_ips)
}

output "nomad_broker_ids" {
  value = concat(module.broker0.ids, module.broker1.ids, module.broker2.ids)
}

output "nomad_namesvr_ssh_ips" {
  value = concat(module.nameServer0.ssh_ip, module.nameServer1.ssh_ip, module.nameServer2.ssh_ip)
}

output "nomad_namesvr_ssh_ip_array" {
  value = [module.nameServer0.ssh_ip, module.nameServer1.ssh_ip, module.nameServer2.ssh_ip]
}

output "nomad_namesvr_public_ips" {
  value = concat(module.nameServer0.public_ips, module.nameServer1.public_ips, module.nameServer2.public_ips)
}

output "namesvr_private_ips" {
  value = concat(module.nameServer0.private_ips, module.nameServer1.private_ips, module.nameServer2.private_ips)
}

output "namesvr_ids" {
  value = concat(module.nameServer0.ids, module.nameServer1.ids, module.nameServer2.ids)
}

output "brokersvr_private_ips" {
  value = concat(module.broker0.private_ips, module.broker1.private_ips, module.broker2.private_ips)
}

output "brokersvr_ids" {
  value = concat(module.broker0.ids, module.broker1.ids, module.broker2.ids)
}

output "nomad_server_ssh_ips" {
  value = local.nomad_server_ssh_ips
}

output "nomad_server_ssh_ip_array" {
  value = [module.nomad_server0.ssh_ip, module.nomad_server1.ssh_ip, module.nomad_server2.ssh_ip]
}
