output consul_servers_ips {
  value = "${module.consul_servers.public_ip}"
}

output nomad_servers_ips {
  value = "${module.nomad_servers.public_ips}"
}

output nomad_clients_ips {
  value = "${module.nomad_clients.public_ips}"
}