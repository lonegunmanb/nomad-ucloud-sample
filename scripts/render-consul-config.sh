echo consul-server-ip-0 ${consul-server-ip-0}
sed -i 's/DATACENTER/${region}/g' /etc/consul.d/consul.hcl
sed -i 's/NODENAME/${node-name}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER1_IP/${consul-server-ip-0}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER2_IP/${consul-server-ip-1}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER3_IP/${consul-server-ip-2}/g' /etc/consul.d/consul.hcl
