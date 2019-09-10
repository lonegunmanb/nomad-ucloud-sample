output "public_ips" {
  value = ucloud_eip.nomad_servers.*.public_ip
}

output "private_ips" {
  value = ucloud_instance.nomad_servers.*.private_ip
}

output "lb_id" {
  value = module.nomad_server_lb.lb_id
}

output "lb_ip" {
  value = module.nomad_server_lb.lb_ip
}

output "ssh_ip" {
  value = local.server_ips
}

output "finish_signal" {
  value = data.null_data_source.finish_signal
}