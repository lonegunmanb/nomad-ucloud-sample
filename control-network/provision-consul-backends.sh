mkdir /project
cd /project
git clone ${terraform_project_url}
cd ${project_dir}/constrol-network/consul
cat <<EOF
      region = "${region}"
      az = ${az}
      locals {
        instance_count = length(var.az)
      }
      root_password = "${root_password}"
      tag = "${tag}"
      vpc_id = "${vpc_id}"
      subnet_id = "${subnet_id}"
      data_volume_size = ${data_volume_size}
      image_id = "${image_id}"
      instance_type = "${instance_type}"
      EOF > terraform.tfvars
terraform init
terraform apply --auto-approve -input=false