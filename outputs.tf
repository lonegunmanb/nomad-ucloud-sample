output cluster_id {
  value = "${data.terraform_remote_state.network.cluster_id}"
}

output az {
  value = "${var.az}"
}
output consul_servers_ips {
  value = "${module.consul_servers.public_ips}"
}

output nomad_servers_ips {
  value = "${module.nomad_servers.public_ips}"
}

output nomad_clients_ips {
  value = "${module.nomad_clients.public_ips}"
}