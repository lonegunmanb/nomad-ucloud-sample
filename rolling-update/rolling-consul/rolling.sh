group=$1
password=$2
cd ..
go get -d ./...
go run rolling_consul.go -module=consul_servers -group=$group -pass=$password
