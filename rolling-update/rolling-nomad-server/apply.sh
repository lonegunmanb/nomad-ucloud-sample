if [ ! -d "/plugin" ]; then
  echo terraform init
  terraform init
else
  echo terraform init -plugin-dir=/plugin
  terraform init -plugin-dir=/plugin
fi

if [ ! -f "/backend/remote.tfvars" ]; then
  terraform apply --auto-approve -parallelism=1 -input=false
else
  terraform apply --auto-approve -parallelism=1 -input=false -var-file=terraform.tfvars -var-file=/backend/remote.tfvars
fi
