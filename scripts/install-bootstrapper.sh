yum install -y epel-release.noarch
yum install -y curl wget git python2 jq.x86_64 unzip
cd /tmp

wget  -nv -O nomad.zip http://hashicorpfile.cn-bj.ufileos.com/nomad_${NOMAD_VERSION}_linux_amd64.zip
unzip nomad.zip
install nomad /usr/local/bin/nomad
nomad version

wget -nv -O terraform.zip http://hashicorpfile.cn-bj.ufileos.com/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform
install terraform /usr/local/bin/terraform
terraform version

wget -nv -O consul.zip http://hashicorpfile.cn-bj.ufileos.com/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip consul.zip
install consul /usr/local/bin/consul
consul --version

wget -nv -O ucloud-cli.tgz http://hashicorpfile.cn-bj.ufileos.com/ucloud-cli-linux-${UCLOUD_CLI_VERSION}-amd64.tgz
tar zxf ucloud-cli.tgz -C /usr/local/bin/

rm -rf /tmp/*

if [ ! -z ${CODE_GIT_URL} ]; then
  mkdir /code
  cd /code
  git clone ${CODE_GIT_URL}
fi
sync
