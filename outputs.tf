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

output nomad_broker_public_ips {
  value = "${module.broker.public_ips}"
}

output nomad_broker_private_ips {
  value = "${module.broker.private_ips}"
}

output nomad_namesvr_public_ips {
  value = "${module.nameServer.public_ips}"
}

output nomad_namesvr_private_ips {
  value = "${module.nameServer.private_ips}"
}