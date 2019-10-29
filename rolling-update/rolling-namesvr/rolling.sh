set -e
group=$1
password=$2
dry=$3
cd ..
go get -d ./...
if [ ! -z $dry ]; then
  go run rolling_client.go -module=nameServer -ip-property=nomad_namesvr_ssh_ip_array -pass=$password -group=$group -dry=true
  go run rolling_client.go -module=nameServerInternalLb -group=$group -dry=true
else
  go run rolling_client.go -module=nameServer -ip-property=nomad_namesvr_ssh_ip_array -pass=$password -group=$group
  go run rolling_client.go -module=nameServerInternalLb -group=$group
fi

cd ..
if [ -z $dry ]; then
  if [ -d "/backend" ]; then
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json -var-file=/backend/remote.tfvars
  else
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json
  fi
else
  if [ -d "/backend" ]; then
    terraform plan -input=false -var-file=terraform.tfvars.json -var-file=/backend/remote.tfvars
  else
    terraform plan -input=false -var-file=terraform.tfvars.json
  fi
  sh untaint_everything.sh
fi
