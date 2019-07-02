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
EOF
cat>/etc/consul.d/consul.json<<-EOF
{
    "client_addr": "0.0.0.0"
}
EOF
echo "syncing"
sync
echo "done"