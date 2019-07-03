echo "write consul.hcl"
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

cat>/etc/nomad.d/server.hcl<<-EOF
datacenter = "DATACENTER"
data_dir = "/data/nomad/data"
name = "NODENAME"
server {
  enabled          = true
  bootstrap_expect = EXPECTEDSVRS
}
EOF

sync
echo "done"