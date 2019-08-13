mkdir /project
cd /project
git clone ${terraform_project_url}
cd ${project_dir}
git checkout ${branch}
cd bootstrap
cat>terraform.tfvars<<-EOF
controller_image = "${controller_image}"
controller_pod_label = "${controller_pod_label}"
k8s_namespace = "${k8s_namespace}"
EOF
terraform apply --auto-approve -input=false
terraform output -json | jq '.backend_ip.value' | xargs printf 'address=\"http://[%s]:8500\"\n' > ../network/backend.tfvars
terraform output -json | jq '.backend_ip.value' | xargs printf 'address=\"http://[%s]:8500\"\n' > ../backend.tfvars
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
terraform apply --auto-approve -input=false