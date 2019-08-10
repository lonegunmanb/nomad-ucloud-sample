output private_ips {
  value = ucloud_instance.consul_server.*.private_ip
}

output uhost_ids {
  value = ucloud_instance.consul_server.*.id
}

output consul_lb_ip {
  value = ucloud_lb.consul_lb.private_ip
}

output consul_lb_id {
  value = ucloud_lb.consul_lb.id
}

output finishSignal {
  value = "${length(ucloud_lb_attachment.consul.*)}-${length(ucloud_disk_attachment.consul_server_data.*)}"
}