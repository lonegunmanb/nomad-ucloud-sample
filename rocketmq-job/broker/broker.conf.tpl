brokerClusterName = {{ env "NOMAD_META_clusterId" }}
brokerName=RaftNode0{{ env "NOMAD_META_index" }}
brokerIP1={{ env "NOMAD_IP_broker" }}
listenPort={{ env "NOMAD_PORT_broker" }}
namesrvAddr={{ with env "NOMAD_META_namesvcName" }}{{range $index, $service := service . }}{{if ne $index 0}};{{end}}{{$service.Address}}:{{$service.Port}}{{end}}{{ end }}
storePathRootDir=/tmp/rmqstore/node00
storePathCommitLog=/tmp/rmqstore/node00/commitlog
enableDLegerCommitLog=true
dLegerGroup={{ env "NOMAD_META_clusterId" }}
dLegerPeers={{ with env "NOMAD_META_brokersvcName" }}{{ range $index, $service := service . }}{{ if ne $index 0 }};{{ end }}n{{ $index }}-{{ $service.Address }}:{{ $service.Port }}{{ end }}{{ end }}
## must be unique
dLegerSelfId=n{{ env "NOMAD_META_index" }}
sendMessageThreadPoolNums=16