set -e
cd /project/${project_dir}
terraform destroy -force -var-file=backend.tfvars
cd network/
terraform destroy -force -var-file=backend.tfvars
cd ../control-network/
terraform destroy -force