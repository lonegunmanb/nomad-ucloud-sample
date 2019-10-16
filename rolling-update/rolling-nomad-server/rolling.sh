set -e
group=$1
dry=$2
cd ..
go get -d ./...
if [ ! -z $dry ]; then
  go run rolling_nomad_server.go -module=nomad_server -group=$group -dry=true
else
  go run rolling_nomad_server.go -module=nomad_server -group=$group
fi

if [ -z $dry ]; then
  cd ..
  if [ -d "/backend" ]; then
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json -var-file=/backend/remote.tfvars
  else
    terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json
  fi
fi
