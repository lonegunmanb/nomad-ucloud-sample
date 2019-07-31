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
systemctl start firewalld
firewall-cmd --zone=trusted --permanent --add-source="${mgrSubnetCidr}"
firewall-cmd --zone=trusted --permanent --add-source="${clientSubnetCidr}"
#TEMPORARY
firewall-cmd --zone=public --permanent --add-service=ssh
#TEMPORARY
firewall-cmd --zone=public --permanent --add-port=8500/tcp
firewall-cmd --reload