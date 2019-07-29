output "public_ips" {
  value = ucloud_eip.nomad_servers.*.public_ip
}

