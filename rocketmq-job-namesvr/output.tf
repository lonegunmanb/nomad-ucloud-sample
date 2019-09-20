output "nameSvrLbIp" {
  value = length(ucloud_eip.nameSvrLoadBalancer.*.public_ip) == 0 ? "" : ucloud_eip.nameSvrLoadBalancer.*.public_ip[0]
}
