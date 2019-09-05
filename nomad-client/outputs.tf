output "public_ips" {
  value = ucloud_eip.nomad_clients.*.public_ip
}

output "private_ips" {
  value = ucloud_instance.nomad_clients.*.private_ip
}

output "ssh_ip" {
  value = local.server_ips
}

output "ids" {
  value = ucloud_instance.nomad_clients.*.id
}

output "finish_signal" {
  value = data.null_data_source.finish_signal
}

