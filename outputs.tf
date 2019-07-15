output cluster_id {
  value = "${data.terraform_remote_state.network.cluster_id}"
}
output region {
  value = "${var.region}"
}
output az {
  value = "${var.az}"
}
output consul_servers_public_ips {
  value = "${module.consul_servers.public_ips}"
}

output consul_servers_private_ips {
  value = "${module.consul_servers.private_ips}"
}

output nomad_servers_ips {
  value = "${module.nomad_servers.public_ips}"
}

output nomad_client_public_ips {
  value = "${module.nomad_clients.public_ips}"
}

output nomad_client_private_ips {
  value = "${module.nomad_clients.private_ips}"
}