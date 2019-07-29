job "${job-name}" {
  datacenters = ["${region}"]
  constraint {
    attribute = "$${node.class}"
    value = "${node-class}"
  }
  constraint {
    attribute = "$${meta.az}"
    operator = "distinct_property"
    value = "${task-limit-per-az}"
  }
  group "broker" {
    count = ${count}
    spread {
      attribute = "$${meta.az}"
    }
    update {
      max_parallel = 1
      health_check = "checks"
      min_healthy_time = "1m"
      healthy_deadline = "5m"
      progress_deadline = "10m"
    }
    ephemeral_disk {
      migrate = true
      size = "500"
      sticky = true
    }
    task "broker" {
      driver = "docker"
      config {
        image = "${broker-image}"
        command = "./mqbroker"
        args = [
          "-c",
          "/opt/rocketmq-${rockermq-version}/conf/dledger/broker.conf"
        ]
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
      service {
        port = "broker"
        check {
          type = "tcp"
          port = "broker"
          interval = "10s"
          timeout = "2s"
        }
      }
      meta {
        clusterId = "${cluster-id}"
        namesrvCount = "3"
        brokerCount = "3"
      }
      template {
        data = <<EOF
        brokerClusterName = {{ env "NOMAD_META_clusterId" }}
        brokerName=broker-{{env "NOMAD_META_clusterId"}}
        brokerIP1={{ env "NOMAD_IP_broker" }}
        listenPort={{ env "NOMAD_PORT_broker" }}
        namesrvAddr={{range $i := loop ((env "NOMAD_META_namesrvCount")|parseInt)}}{{if ne $i 0}};{{end}}localhost:{{env (printf "NOMAD_PORT_outboundProxy_namesvrTcp%d" $i)}}{{end}}
        storePathRootDir=/tmp/rmqstore/node00
        storePathCommitLog=/tmp/rmqstore/node00/commitlog
        enableDLegerCommitLog=true
        dLegerGroup={{ env "NOMAD_META_clusterId" }}
        dLegerPeers={{range $i := loop ((env "NOMAD_META_brokerCount")|parseInt)}}{{$index := (env "NOMAD_ALLOC_INDEX")|parseInt}}{{if ne $i 0}};{{end}}n{{$i}}-{{if ne $i $index}}localhost:{{env (printf "NOMAD_PORT_outboundProxy_dledger%d" $i)}}{{else}}{{env "NOMAD_ADDR_dledger"}}{{end}}{{end}}
        ## must be unique
        dLegerSelfId=n{{ env "NOMAD_ALLOC_INDEX" }}
        sendMessageThreadPoolNums=16
        clientCloseSocketIfTimeout=true
        EOF
        destination = "local/conf/broker.conf"
        change_mode = "noop"
      }
    }
    task "inboundProxy" {
      driver = "exec"
      config {
        command = "consul"
        args = [
          "connect",
          "proxy",
          "-service",
          "${brokersvc-name}$${NOMAD_ALLOC_INDEX}",
          "-service-addr",
          "$${NOMAD_ADDR_broker_dledger}",
          "-listen",
          ":$${NOMAD_PORT_tcp}",
          "-register",
        ]
      }

      resources {
        network {
          port "tcp" {}
        }
      }
    }
    task "outboundProxy" {
      driver = "exec"
      config {
        command = "consul"
        args = [
          "connect",
          "proxy",
          "-service",
          "namesvc-sidecar-${cluster-id}-$${NOMAD_ALLOC_INDEX}-0",
          "-upstream",
          "namesvc-${cluster-id}-0:$${NOMAD_PORT_namesvrTcp0}",
          "-service",
          "namesvc-sidecar-${cluster-id}-$${NOMAD_ALLOC_INDEX}-1",
          "-upstream",
          "namesvc-${cluster-id}-1:$${NOMAD_PORT_namesvrTcp1}",
          "-service",
          "namesvc-sidecar-${cluster-id}-$${NOMAD_ALLOC_INDEX}-2",
          "-upstream",
          "namesvc-${cluster-id}-2:$${NOMAD_PORT_namesvrTcp2}",
          "-service",
          "broker-dledger-sidecar-${cluster-id}-$${NOMAD_ALLOC_INDEX}-0",
          "-upstream",
          "${brokersvc-name}0:$${NOMAD_PORT_dledger0}",
          "-service",
          "broker-dledger-sidecar-${cluster-id}-$${NOMAD_ALLOC_INDEX}-1",
          "-upstream",
          "${brokersvc-name}1:$${NOMAD_PORT_dledger1}",
          "-service",
          "broker-dledger-sidecar-${cluster-id}-$${NOMAD_ALLOC_INDEX}-2",
          "-upstream",
          "${brokersvc-name}2:$${NOMAD_PORT_dledger2}",
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