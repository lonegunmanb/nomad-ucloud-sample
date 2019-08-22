echo "write consul.d/consul.hcl"
mkdir --parents /opt/consul/data
chown --recursive consul:consul /opt/consul/data

cat>/etc/consul.d/consul.hcl<<-EOF
datacenter = "DATACENTER"
data_dir = "/opt/consul/data"
node_name = "NODENAME"
retry_join = ["CONSUL_SERVER1_IP", "CONSUL_SERVER2_IP", "CONSUL_SERVER3_IP"]
performance {
  raft_multiplier = 1
}
EOF

echo "write nomad.d/server.hcl"
cat>/etc/nomad.d/server.hcl<<-EOF
region = "REGION"
datacenter = "DATACENTER"
data_dir = "/data/nomadAgent"
name = "NODENAME"
server {
  data_dir = "/data/nomadServer"
  enabled          = true
  bootstrap_expect = EXPECTEDSVRS
  job_gc_threshold = "1h"
  deployment_gc_threshold = "10m"
}
EOF

sync
echo "done"