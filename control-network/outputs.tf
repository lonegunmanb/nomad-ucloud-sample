output vpcId {
  value = ucloud_vpc.vpc.id
}

output controllerLbIp {
  value = ucloud_eip.controlerLbEip.public_ip
}

output controlerIps {
  value = ucloud_eip.eip.*.public_ip
}