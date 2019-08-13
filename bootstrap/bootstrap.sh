mkdir /project
cd /project
git clone ${terraform_project_url}
cd ${project_dir}
git checkout ${branch}
cd control-network
cat>terraform.tfvars<<-EOF
ucloud_pub_key = "${ucloud_pub_key}"
ucloud_secret = "${ucloud_secret}"
region = "${region}"
region_id = "${region_id}"
az = [${az}]
project_id = "${project_id}"
cidr = "${controller_cidr}"
vpcName = "controllerVpc"
subnetName = "controllerSubnet"
consul_image_id = "${consul_server_image_id}"
controller_image_id = ""
controler_instance_type = ""
allow_ip = "${allow_ip}"
root_password = ""

terraform_project_url = ""
git_branch = ""
project_root_dir = ""
project_dir = ""
consul_root_password = "${backend_consul_root_password}"
consul_data_volume_size = ${consul_data_volume_size}
consul_instance_type = "${consul_instance_type}"
ipv6_api_url = "${ipv6_api_url}"
controller_count = 0
provision_from_kun = true
EOF
terraform init -plugin-dir=/plugin
terraform apply --auto-approve -input=false
terraform output -json | jq '.backend_ip.value' | xargs printf 'address=\"http://[%s]:8500\"\n' > ../network/backend.tfvars
terraform output -json | jq '.backend_ip.value' | xargs printf 'address=\"http://[%s]:8500\"\n' > ../backend.tfvars
terraform output -json | jq '.backend_ip.value' | xargs printf 'remote_state_backend_url=\"http://[%s]:8500\"\n' >> ../backend.tfvars
cat>../network/terraform.tfvars.json<<-EOF
{
  "region": "${region}",
  "ucloud_pub_key": "${ucloud_pub_key}",
  "ucloud_secret": "${ucloud_secret}",
  "project_id": "${project_id}",
  "mgrVpcCidr": "${mgrVpcCidr}",
  "clientVpcCidr": "${clientVpcCidr}"
}
EOF
cat>../terraform.tfvars.json<<-EOF
{
    "allow_ip": "${allow_ip}",
    "az": [${az}],
    "clientSubnetCidr": "${clientVpcCidr}",
    "consul_server_image_id": "${consul_server_image_id}",
    "consul_server_root_password": "${consul_server_root_password}",
    "consul_server_type": "${consul_server_type}",
    "mgrSubnetCidr": "${mgrVpcCidr}",
    "nomad_client_broker_type": "${nomad_client_broker_type}",
    "nomad_client_image_id": "${nomad_client_image_id}",
    "nomad_client_namesvr_type": "${nomad_client_namesvr_type}",
    "nomad_client_root_password": "${nomad_client_root_password}",
    "nomad_server_image_id": "${nomad_server_image_id}",
    "nomad_server_root_password": "${nomad_server_root_password}",
    "nomad_server_type": "${nomad_server_type}",
    "project_id": "${project_id}",
    "region": "${region}",
    "ucloud_pub_key": "${ucloud_pub_key}",
    "ucloud_secret": "${ucloud_secret}",
    "TF_PLUGIN_CONSUL_VERSION": "${TF_PLUGIN_CONSUL_VERSION}",
    "TF_PLUGIN_NULL_VERSION": "${TF_PLUGIN_NULL_VERSION}",
    "TF_PLUGIN_TEMPLATE_VERSION": "${TF_PLUGIN_TEMPLATE_VERSION}",
    "TF_PLUGIN_UCLOUD_VERSION": "${TF_PLUGIN_UCLOUD_VERSION}"
}
EOF
cd ../network
terraform init -plugin-dir=/plugin -backend-config=backend.tfvars
terraform workspace new ${cluster_id}
terraform apply --auto-approve -input=false
cd ..
terraform init -plugin-dir=/plugin -backend-config=backend.tfvars
terraform workspace new ${cluster_id}
terraform apply --auto-approve -input=false -var-file=backend.tfvars -var-file=terraform.tfvars.json