echo "write nomad.d/client.hcl"
mkdir --parents /opt/consul/data
cat>/etc/nomad.d/client.hcl<<-EOF
region = "REGION"
datacenter = "DATACENTER"
data_dir = "/opt/nomad/data"
name = "NODENAME"
client {
  enabled = true
  node_class = "CLASS"
  alloc_dir = "/data"
  reserved {
    cpu = 100
    memory = 1024
  }
  options {
      "docker.privileged.enabled" = "true"
  }
  META
}
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}

EOF
echo "done"
