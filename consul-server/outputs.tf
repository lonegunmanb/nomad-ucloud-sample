output "public_ips" {
  value = ucloud_eip.consul_servers.*.public_ip
}

output "private_ips" {
  value = ucloud_instance.consul_server.*.private_ip
}

output "lb_ip" {
  value = module.consulLb.lb_ip
}

output "lb_id" {
  value = module.consulLb.lb_id
}

output "ssh_ip" {
  value = local.server_ips
}

output "finish_signal" {
  value = data.null_data_source.finish_signal
}
