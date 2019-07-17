mkfs.ext4 /dev/vdb
mount /dev/vdb /data
echo 'mount /dev/vdb /data'>>/etc/rc.d/rc.local
sed -i 's/SERVICE_DESCRIPTION/Consul Client/g' /etc/systemd/system/consul.service
sed -i 's/REGION/${region}/g' /etc/nomad.d/client.hcl
sed -i 's/DATACENTER/${region}/g' /etc/consul.d/consul.hcl
sed -i 's/DATACENTER/${az}/g' /etc/nomad.d/client.hcl
sed -i 's/AZ/${az}/g' /etc/nomad.d/client.hcl
sed -i 's/NODENAME/${node-name}/g' /etc/nomad.d/client.hcl
sed -i 's/CLASS/${node-class}/g' /etc/nomad.d/client.hcl
sed -i 's/META/${node-meta}/g' /etc/nomad.d/client.hcl
sed -i 's/NODENAME/${node-name}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER1_IP/${consul-server-ip-0}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER2_IP/${consul-server-ip-1}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER3_IP/${consul-server-ip-2}/g' /etc/consul.d/consul.hcl
sed -i 's/SERVICE_DESCRIPTION/Nomad Client/g' /etc/systemd/system/nomad.service
systemctl enable consul
systemctl start consul
systemctl enable nomad
systemctl start nomad
systemctl restart docker