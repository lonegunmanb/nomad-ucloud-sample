output mgrVpcId {
  value = data.ucloud_vpcs.mgrVpc.vpcs.*.id[0]
}

output clientVpcId {
  value = data.ucloud_vpcs.clientVpc.vpcs.*.id[0]
}

output mgrSubnetId {
  value = data.ucloud_subnets.mgrSubnet.subnets.*.id[0]
}

output clientSubnetId {
  value = data.ucloud_subnets.clientSubnet.subnets.*.id[0]
}

output cluster_id {
  value = local.cluster_id
}