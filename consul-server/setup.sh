mkfs.xfs /dev/vdb
mount /dev/vdb /data
echo 'mount /dev/vdb /data'>>/etc/rc.d/rc.local
mkdir --parents /data/consul
chown --recursive consul:consul /data/consul
sed -i 's/SERVICE_DESCRIPTION/Consul Server/g' /etc/systemd/system/consul.service
sed -i 's/CLUSTER/${cluster}/g' /etc/consul.d/consul_service.json
systemctl enable consul
systemctl start consul
