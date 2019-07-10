job "${job-name}" {
  datacenters = ["cn-bj2"]
  affinity {
    attribute = "$${meta.az}"
    value     = "${az}"
    weight    = 100
  }
  group "broker" {
    task "brokerTask" {
      driver = "docker"
      config {
        image = "${broker-image}"
        command = "./mqbroker"
        args = ["-c", "/opt/rocketmq-${rockermq-version}/conf/dledger/broker.conf"]
        volumes = [
          "local/conf:/opt/rocketmq-${rockermq-version}/conf/dledger",
        ]
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
        cluster-id = "${cluster-id}"
      }
      artifact {
        source = "${broker-config}"
        destination = "local/conf"
      }
      template {
        source = "local/conf/broker.conf.tpl"
        destination = "local/conf/broker.conf"
      }
    }
    task "broker-proxy" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "broker-${cluster-id}-${index}",
          "-service-addr", "$${NOMAD_ADDR_brokerTask_broker}",
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
    task "dledgerProxy" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "dledger-${cluster-id}-${index}",
          "-service-addr", "$${NOMAD_ADDR_brokerTask_dledger}",
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

//sidecar
    ${task-dledger-sidecar0}
    ${task-dledger-sidecar1}
    ${task-dledger-sidecar2}

    ${task-namesvr-sidecar0}
    ${task-namesvr-sidecar1}
    ${task-namesvr-sidecar2}
  }
}