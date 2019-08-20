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
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
acl = {
    enabled = true,
    tokens = {
      default = "CONSUL_TOKEN"
    }
}
EOF

echo "write nomad.d/client.hcl"
mkdir --parents /opt/consul/data
cat>/etc/nomad.d/client.hcl<<-EOF
region = "REGION"
datacenter = "DATACENTER"
data_dir = "/opt/consul/data"
name = "NODENAME"
client {
  enabled = true
  node_class = "CLASS"
  META
}
consul {
  address = "127.0.0.1:8500"
  token   = "CONSUL_TOKEN"
}
EOF
sync
echo "done"