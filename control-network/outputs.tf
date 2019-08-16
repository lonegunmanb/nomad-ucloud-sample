output vpcId {
  value = ucloud_vpc.vpc.id
}

output backend_ip {
  value = var.provision_from_kun ? module.consul_backend_lb_ipv6.ipv6s[0] : module.backend_lb.lb_ip
}

output backend_lb_id {
  value = module.backend_lb.lb_id
}