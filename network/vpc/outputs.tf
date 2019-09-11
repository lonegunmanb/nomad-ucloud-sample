output vpc_id {
  value = var.vpc_count == 0 ? "" : ucloud_vpc.vpc.*.id[0]
}

output subnetId {
  value = var.vpc_count == 0 ? "" : ucloud_subnet.subnet.*.id[0]
}
