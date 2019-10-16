set -e
group=$1
password=$2
dry=$3
cd ..
go get -d ./...
#cat rolling.go
if [ ! -z $dry ]; then
  go run rolling_client.go -module=broker -ip-property=nomad_broker_ssh_ip_array -pass=$password -group=$group -dry=true
else
  go run rolling_client.go -module=broker -ip-property=nomad_broker_ssh_ip_array -pass=$password -group=$group
fi

cd ..
if [ -z $dry ]; then
  if [ -d "/backend" ]; then
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json -var-file=/backend/remote.tfvars
  else
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json
  fi
fi
