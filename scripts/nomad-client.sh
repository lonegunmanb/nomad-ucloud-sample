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

mkdir --parents /opt/consul/data
cat>/etc/nomad.d/client.hcl<<-EOF
datacenter = "DATACENTER"
data_dir = "/opt/consul/data"
name = "NODENAME"
client {
  enabled = true
}
EOF
sync
echo "done"