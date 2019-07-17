job "${job-name}" {
  datacenters = ["${az}"]
  constraint {
    attribute = "$${node.class}"
    value     = "${node-class}"
  }
  group "broker" {
    task "broker" {
      driver = "docker"
      config {
        image = "${broker-image}"
        command = "./mqbroker"
        args = ["-c", "/opt/rocketmq-${rockermq-version}/conf/dledger/broker.conf"]
        volumes = [
          "local/conf:/opt/rocketmq-${rockermq-version}/conf/dledger",
        ]
        network_mode = "host"
      }
      resources {
        cpu = 1000
        memory = 4096
        network {
          port "broker" {}
          port "dledger" {}
        }
      }
      meta {
        index = "${index}"
        clusterId = "${cluster-id}"
        namesrvCount = "3"
        brokerCount = "3"
      }
      template {
        data = <<EOF
        brokerClusterName = {{ env "NOMAD_META_clusterId" }}
        brokerName=RaftNode0{{ env "NOMAD_META_index" }}
        brokerIP1={{ env "NOMAD_IP_broker" }}
        listenPort={{ env "NOMAD_PORT_broker" }}
        namesrvAddr={{range $i := loop ((env "NOMAD_META_namesrvCount")|parseInt)}}{{if ne $i 0}};{{end}}localhost:{{env (printf "NOMAD_PORT_outputProxy_namesvrTcp%d" $i)}}{{end}}
        storePathRootDir=/tmp/rmqstore/node00
        storePathCommitLog=/tmp/rmqstore/node00/commitlog
        enableDLegerCommitLog=true
        dLegerGroup={{ env "NOMAD_META_clusterId" }}
        dLegerPeers={{range $i := loop ((env "NOMAD_META_brokerCount")|parseInt)}}{{$index := env "NOMAD_META_index"|parseInt}}{{if ne $i 0}};{{end}}n{{$i}}-{{if ne $i $index}}localhost:{{env (printf "NOMAD_PORT_outputProxy_namesvrTcp%d" $i)}}{{else}}{{env "NOMAD_ADDR_dledger"}}{{end}}{{end}}
        ## must be unique
        dLegerSelfId=n{{ env "NOMAD_META_index" }}
        sendMessageThreadPoolNums=16
        EOF
        destination = "local/conf/broker.conf"
        change_mode = "noop"
      }
    }
    task "inputProxy" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "${brokersvc-name}${index}",
          "-service-addr", "$${NOMAD_ADDR_broker_dledger}",
          "-listen", ":$${NOMAD_PORT_tcp}",
          "-register",
        ]
      }

      resources {
        network {
          port "tcp" {}
        }
      }
    }
    task "outputProxy" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "namesvc-sidecar-${cluster-id}-${index}-0",
          "-upstream", "namesvc-${cluster-id}-0:$${NOMAD_PORT_namesvrTcp0}",
          "-service", "namesvc-sidecar-${cluster-id}-${index}-1",
          "-upstream", "namesvc-${cluster-id}-1:$${NOMAD_PORT_namesvrTcp1}",
          "-service", "namesvc-sidecar-${cluster-id}-${index}-2",
          "-upstream", "namesvc-${cluster-id}-2:$${NOMAD_PORT_namesvrTcp2}",
          "-service", "broker-dledger-sidecar-${cluster-id}-${index}-0",
          "-upstream", "${brokersvc-name}0:$${NOMAD_PORT_dledger0}",
          "-service", "broker-dledger-sidecar-${cluster-id}-${index}-1",
          "-upstream", "${brokersvc-name}1:$${NOMAD_PORT_dledger1}",
          "-service", "broker-dledger-sidecar-${cluster-id}-${index}-2",
          "-upstream", "${brokersvc-name}2:$${NOMAD_PORT_dledger2}",
        ]
      }
      resources {
        network {
          port "namesvrTcp0" {}
          port "namesvrTcp1" {}
          port "namesvrTcp2" {}
          port "dledger0" {}
          port "dledger1" {}
          port "dledger2" {}
        }
      }
    }
  }
}