mkfs.xfs /dev/vdb
mount /dev/vdb /data

groupadd -g 3000 rocketmq
useradd -u 3000 -g 3000 -m -s /bin/bash rocketmq
chown :rocketmq /data
chmod g+rw /data

echo 'mount /dev/vdb /data'>>/etc/rc.d/rc.local
sed -i 's/SERVICE_DESCRIPTION/Consul Client/g' /etc/systemd/system/consul.service
sed -i 's/REGION/${region}/g' /etc/nomad.d/client.hcl
sed -i 's/DATACENTER/${region}/g' /etc/nomad.d/client.hcl
sed -i 's/AZ/${az}/g' /etc/nomad.d/client.hcl
sed -i 's/NODENAME/${node-name}/g' /etc/nomad.d/client.hcl
sed -i 's/CLASS/${node-class}/g' /etc/nomad.d/client.hcl
sed -i 's/META/${node-meta}/g' /etc/nomad.d/client.hcl
sed -i 's/SERVICE_DESCRIPTION/Nomad Client/g' /etc/systemd/system/nomad.service
systemctl enable consul
systemctl start consul
systemctl enable nomad
systemctl start nomad
#restart docker service MUST be the LAST command of setup
systemctl restart docker
