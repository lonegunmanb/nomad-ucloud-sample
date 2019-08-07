output private_ips {
  value = ucloud_instance.consul_server.*.private_ip
}

output uhost_ids {
  value = ucloud_instance.consul_server.*.id
}