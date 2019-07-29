output "vpc_id" {
  value = ucloud_vpc.consul_vpc.id
}

output "consul_subnet_id" {
  value = ucloud_subnet.consul_server.id
}

output "nomad_subnet_id" {
  value = ucloud_subnet.nomad.id
}

output "cluster_id" {
  value = var.cluster_id
}

