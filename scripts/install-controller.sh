yum install -y unzip wget telnet git
cd /tmp
TERRAFORM_VERSION = $TERRAFORM_VERSION
CONSUL_VERSION = $CONSUL_VERSION
NOMAD_VERSION = $NOMAD_VERSION
GO_VERSION = $GO_VERSION

wget -nv -O terraform.zip http://hashicorpfile.cn-bj.ufileos.com/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform
install terraform /usr/local/bin/terraform
terraform version

mkdir /plugin
cd /plugin
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-consul_v2.5.0_x4
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-null_v2.1.2_x4
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-template_v2.1.2_x4
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-ucloud_v1.11.1_x4
chmod +x terraform-provider-consul_v2.5.0_x4
chmod +x terraform-provider-null_v2.1.2_x4
chmod +x terraform-provider-template_v2.1.2_x4
chmod +x terraform-provider-ucloud_v1.11.1_x4
cd /tmp

wget -nv -O consul.zip http://hashicorpfile.cn-bj.ufileos.com/consul_${CONSUL_VERSION}_linux_amd64.zip
unzip consul.zip
install consul /usr/local/bin/consul
consul --version
consul -autocomplete-install
complete -C /usr/local/bin/consul consul

wget -nv -O nomad.zip http://hashicorpfile.cn-bj.ufileos.com/nomad_${NOMAD_VERSION}_linux_amd64.zip
unzip nomad.zip
install nomad /usr/local/bin/nomad
nomad version

wget -nv -O go.tar.gz https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go.tar.gz
mkdir ~/go
mkdir ~/go/bin
mkdir ~/go/src
echo export GOPATH=~/go >> ~/.bashrc
echo export PATH=$PATH:/usr/local/go/bin:~/go/bin >> ~/.bashrc
go version

rm -rf /tmp/*