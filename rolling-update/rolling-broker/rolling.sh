password=$1
group=$2
cd ../nomad-client
go get -d ./...
#cat rolling.go
go run rolling.go -module=broker -ip-property=nomad_broker_ssh_ip_array -pass=$password -group=$group
