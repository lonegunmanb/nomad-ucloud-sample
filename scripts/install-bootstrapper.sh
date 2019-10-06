yum install -y epel-release.noarch
yum install -y curl wget git python2 jq.x86_64 unzip
cd /tmp

wget  -nv -O nomad.zip ${FILE_SERVER}/nomad_${NOMAD_VERSION}_linux_amd64.zip
unzip nomad.zip
install nomad /usr/local/bin/nomad
nomad version

wget -nv -O terraform.zip ${FILE_SERVER}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform
install terraform /usr/local/bin/terraform
terraform version

wget -nv -O consul.zip ${FILE_SERVER}/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip consul.zip
install consul /usr/local/bin/consul
consul --version

wget -nv -O ucloud-cli.tgz ${FILE_SERVER}/ucloud-cli-linux-${UCLOUD_CLI_VERSION}-amd64.tgz
tar zxf ucloud-cli.tgz -C /usr/local/bin/

rm -rf /tmp/*

if [ ! -z ${CODE_GIT_URL} ]; then
  mkdir /code
  cd /code
  git clone ${CODE_GIT_URL}
fi
sync
