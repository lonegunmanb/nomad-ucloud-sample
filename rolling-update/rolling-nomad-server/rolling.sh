group=$1
cd ..
go get -d ./...
#cat rolling.go
go run rolling.go -module=nomad_server -group=$group
