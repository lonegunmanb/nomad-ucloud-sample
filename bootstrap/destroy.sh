cd /project/${project_dir}
if [ ! -f "destroyed" ]; then
  terraform destroy -force -var-file=backend.tfvars
  touch destroyed
fi
cd network
set -e
if [ ! -f "destroyed" ]; then
  terraform destroy -force -var-file=backend.tfvars
  touch destroyed
fi
cd ../control-network
terraform destroy -force