cd ${project_dir}/control-network/consul
cat > terraform.tfvars <<EOF
      project_id = "${project_id}"
      ucloud_pub_key = "${ucloud_pub_key}"
      ucloud_secret = "${ucloud_secret}"
      region = "${region}"
      az = ${az}
      root_password = "${root_password}"
      tag = "${tag}"
      vpc_id = "${vpc_id}"
      subnet_id = "${subnet_id}"
      data_volume_size = ${data_volume_size}
      image_id = "${image_id}"
      instance_type = "${instance_type}"
      charge_type = "${charge_type}"
EOF
export TF_LOG=DEBUG
terraform init -plugin-dir=/plugin
terraform apply --auto-approve -input=false