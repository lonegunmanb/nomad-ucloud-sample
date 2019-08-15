echo "Installing Nomad..."
NOMAD_VERSION=$NOMAD_VERSION
cd /tmp/
wget  -O nomad.zip http://hashicorpfile.cn-bj.ufileos.com/nomad_${NOMAD_VERSION}_linux_amd64.zip
unzip nomad.zip
install nomad /usr/local/bin/nomad
mkdir -p /etc/nomad.d
chmod a+w /etc/nomad.d

MAINPID='$MAINPID'
touch /etc/systemd/system/nomad.service
cat>/etc/systemd/system/nomad.service<<-EOF
[Unit]
Description="SERVICE_DESCRIPTION"
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP ${MAINPID}
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF

for bin in cfssl cfssl-certinfo cfssljson
do
  echo "Installing $bin..."
  wget -O /tmp/${bin} https://pkg.cfssl.org/R1.2/${bin}_linux-amd64
  install /tmp/${bin} /usr/local/bin/${bin}
done
nomad -autocomplete-install
sync