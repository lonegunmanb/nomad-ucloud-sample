yum install -y sed unzip vim
cd /tmp
CONSUL_VERSION=$CONSUL_VERSION
wget -O consul.zip http://hashicorpfile.cn-bj.ufileos.com/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip consul.zip
install consul /usr/local/bin/consul
consul --version
consul -autocomplete-install
complete -C /usr/local/bin/consul consul
echo "add user consul"
useradd --system --home /etc/consul.d --shell /bin/false consul

mkdir --parents /etc/consul.d
touch /etc/consul.d/consul.hcl
chown --recursive consul:consul /etc/consul.d
chmod 640 /etc/consul.d/consul.hcl

echo "write consul.service"
cat>/etc/systemd/system/consul.service<<-EOF
[Unit]
Description="SERVICE_DESCRIPTION"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul.d/consul.hcl

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
ExecReload=/usr/local/bin/consul reload
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
sync