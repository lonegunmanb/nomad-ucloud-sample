output mgrVpcId {
  value = ucloud_vpc.vpc.id
}

output clientVpcId {
  value = ucloud_vpc.vpc.id
}

output mgrSubnetId {
  value = ucloud_subnet.subnet.id
}

output clientSubnetId {
  value = ucloud_subnet.subnet.id
}

output cluster_id {
  value = local.cluster_id
}