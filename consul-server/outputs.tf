output "public_ips" {
  value = ucloud_eip.consul_servers.*.public_ip
}

output "private_ips" {
  value = ucloud_instance.consul_server.*.private_ip
}

output "lb_ip" {
  value = module.consulLb.lb_ip
}

output rootAccessorId {
  value = local.rootAccessorId
}

output "rootSecretId" {
  value = local.rootSecretId
}

output "agent_token" {
  value = data.external.agent_secret.result["secretId"]
}