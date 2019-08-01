output private_ips {
  value = ucloud_instance.consul_server.*.private_ip
}

