output "public_ips" {
  value = "${ucloud_eip.nomad_clients.*.public_ip}"
}