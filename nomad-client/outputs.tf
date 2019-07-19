output public_ips {
  value = "${ucloud_eip.nomad_clients.*.public_ip}"
}

output private_ips {
  value = "${ucloud_instance.nomad_clients.*.private_ip}"
}

output ids {
  value = "${ucloud_instance.nomad_clients.*.id}"
}