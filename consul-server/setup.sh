mkfs.ext4 /dev/vdb
mount /dev/vdb /data
echo 'mount /dev/vdb /data'>>/etc/rc.d/rc.local
mkdir --parents /data/consul
chown --recursive consul:consul /data/consul
sed -i 's/SERVICE_DESCRIPTION/Consul Server/g' /etc/systemd/system/consul.service
sed -i 's/DATACENTER/${region}/g' /etc/consul.d/consul.hcl
sed -i 's/NODENAME/${node-name}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER1_IP/${consul-server-ip-0}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER2_IP/${consul-server-ip-1}/g' /etc/consul.d/consul.hcl
sed -i 's/CONSUL_SERVER3_IP/${consul-server-ip-2}/g' /etc/consul.d/consul.hcl
systemctl enable consul
systemctl start consul