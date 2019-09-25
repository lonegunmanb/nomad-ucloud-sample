if [ ! -f "/backend/remote.tfvars" ]; then
  terraform apply --auto-approve -parallelism=1 -input=false
else
  terraform apply --auto-approve -parallelism=1 -input=false -var-file=terraform.tfvars -var-file=/backend/remote.tfvars
fi
