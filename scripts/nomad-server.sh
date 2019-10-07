echo "write nomad.d/server.hcl"
cat>/etc/nomad.d/server.hcl<<-EOF
region = "REGION"
datacenter = "DATACENTER"
data_dir = "/data/nomadAgent"
name = "NODENAME"
server {
  data_dir = "/data/nomadServer"
  enabled          = true
  bootstrap_expect = 3
  job_gc_threshold = "1h"
  deployment_gc_threshold = "10m"
}
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
EOF

sync
echo "done"
