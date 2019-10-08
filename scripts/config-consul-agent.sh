echo "write consul.d/consul.hcl"
if [[ ! -d /opt/consul/data ]]; then
  mkdir --parents /opt/consul/data
  chown --recursive consul:consul /opt/consul/data
fi

cat>/etc/consul.d/consul.hcl<<-EOF
datacenter = "DATACENTER"
data_dir = "/opt/consul/data"
node_name = "NODENAME"
retry_join = ["CONSUL_SERVER1_IP", "CONSUL_SERVER2_IP", "CONSUL_SERVER3_IP"]
performance {
  raft_multiplier = 1
}
bind_addr = "{{ GetInterfaceIP \"eth0\" }}"
client_addr = "127.0.0.1 {{ GetInterfaceIP \"eth0\" }}"
EOF
