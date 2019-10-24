echo "write consul.hcl"
cat>/etc/consul.d/consul.hcl<<-EOF
datacenter = "DATACENTER"
data_dir = "/data/consul"
client_addr = "0.0.0.0"
node_name = "NODENAME"
retry_join = ["CONSUL_SERVER1_IP", "CONSUL_SERVER2_IP", "CONSUL_SERVER3_IP"]
performance {
  raft_multiplier = 1
}
server = true
bootstrap_expect = 3
ui = true
connect {
  enabled = true
}
telemetry {
  prometheus_retention_time = "10s"
}
EOF
cat>/etc/consul.d/consul.json<<-EOF
{
    "client_addr": "0.0.0.0"
}
EOF
cat>/etc/consul.d/consul_service.json<<-EOF
{
  "service": {
    "name": "consul_http",
    "port": 8500,
    "tags": ["cluster-CLUSTER", "http"]
  }
}
EOF
echo "done"
