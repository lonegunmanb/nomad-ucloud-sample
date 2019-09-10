output mgrVpcId {
  value = data.ucloud_vpcs.vpc.vpcs.*.id[0]
}

output clientVpcId {
  value = data.ucloud_vpcs.vpc.vpcs.*.id[0]
}

output mgrSubnetId {
  value = data.ucloud_subnets.subnet.subnets.*.id[0]
}

output clientSubnetId {
  value = data.ucloud_subnets.subnet.subnets.*.id[0]
}

output cluster_id {
  value = local.cluster_id
}