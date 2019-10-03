group=$1
password=$2
cd ../nomad-client
go get -d ./...
#cat rolling.go
go run rolling.go -module=nameServer -ip-property=nomad_namesvr_ssh_ip_array -pass=$password -group=$group
