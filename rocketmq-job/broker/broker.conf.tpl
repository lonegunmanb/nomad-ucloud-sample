brokerClusterName = {{ env "NOMAD_META_clusterId" }}
brokerName=RaftNode0{{ env "NOMAD_META_index" }}
brokerIP1={{ env "NOMAD_IP_broker" }}
listenPort={{ env "NOMAD_PORT_broker" }}
namesrvAddr={{with env "NOMAD_META_clusterId"}}localhost:{{env (printf "NOMAD_PORT_namesvc%s0_tcp" .)}};localhost:{{env (printf "NOMAD_PORT_namesvc%s1_tcp" .)}};localhost:{{env (printf "NOMAD_PORT_namesvc%s2_tcp" .)}}{{end}}
storePathRootDir=/tmp/rmqstore/node00
storePathCommitLog=/tmp/rmqstore/node00/commitlog
enableDLegerCommitLog=true
dLegerGroup={{ env "NOMAD_META_clusterId" }}
dLegerPeers={{ with env "NOMAD_META_brokersvcName" }}{{ range $index, $service := service . }}{{ if ne $index 0 }};{{ end }}n{{key (printf "nomad_client_index/%s" $service.Address)}}-{{ $service.Address }}:{{ $service.Port }}{{ end }}{{ end }}
## must be unique
dLegerSelfId=n{{ env "NOMAD_META_index" }}
sendMessageThreadPoolNums=16