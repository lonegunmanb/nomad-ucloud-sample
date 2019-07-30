output mgrVpcId {
  value = module.mgrVpc.vpc_id
}

output clientVpcId {
  value = module.clientVpc.vpc_id
}

output mgrSubnetId {
  value = module.mgrVpc.subnetId
}

output clientSubnetId {
  value = module.clientVpc.subnetId
}

output cluster_id {
  value = var.cluster_id
}