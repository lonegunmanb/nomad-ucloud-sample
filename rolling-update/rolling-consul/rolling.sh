set -e
group=$1
password=$2
dry=$3
cd ..
go get -d ./...
if [ ! -z $dry ]; then
  go run rolling_consul.go -module=consul_servers -group=$group -pass=$password -dry=true
else
  go run rolling_consul.go -module=consul_servers -group=$group -pass=$password
fi

if [ -z $dry ]; then
  cd ..
  if [ -d "/backend" ]; then
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json -var-file=/backend/remote.tfvars
  else
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json
  fi
fi
