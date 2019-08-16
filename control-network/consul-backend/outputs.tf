output private_ips {
  value = ucloud_instance.consul_server.*.private_ip
}

output uhost_ids {
  value = ucloud_instance.consul_server.*.id
}

output finishSignal {
  value = length(ucloud_disk_attachment.consul_server_data.*)
}