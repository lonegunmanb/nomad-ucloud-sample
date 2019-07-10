brokerClusterName = {{ env "NOMAD_META_cluster-id" }}
brokerName=RaftNode0{{ env "NOMAD_META_index" }}
listenPort={{ env "NOMAD_PORT_broker-task_broker" }}
namesrvAddr=localhost:{{ env "NOMAD_PORT_namesvr0_tcp" }};localhost:{{ env "NOMAD_PORT_namesvr1_tcp" }};localhost:{{ env "NOMAD_PORT_namesvr2_tcp" }}
storePathRootDir=/tmp/rmqstore/node00
storePathCommitLog=/tmp/rmqstore/node00/commitlog
enableDLegerCommitLog=true
dLegerGroup={{ env "NOMAD_META_cluster-id" }}
dLegerPeers=n0-localhost:{{ env "NOMAD_PORT_dledger0_tcp" }};n1-localhost:{{ env "NOMAD_PORT_dledger1_tcp" }};n2-localhost:{{ env "NOMAD_PORT_dledger2_tcp" }}
## must be unique
dLegerSelfId=n{{ env "NOMAD_META_index" }}
sendMessageThreadPoolNums=16
