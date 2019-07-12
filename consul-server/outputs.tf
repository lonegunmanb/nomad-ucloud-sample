output "public_ips" {
  value = "${ucloud_eip.consul_servers.*.public_ip}"
}

output "consul_server_private_ips" {
  value = "${ucloud_instance.consul_server.*.private_ip}"
}