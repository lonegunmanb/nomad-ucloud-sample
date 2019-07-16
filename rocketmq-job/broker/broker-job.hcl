job "${job-name}" {
  datacenters = ["cn-bj2"]
  constraint {
    attribute = "$${meta.az}"
    value     = "${az}"
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
      service {
        name = "${brokersvc-name}"
        port = "dledger"
        check {
          type     = "tcp"
          port     = "dledger"
          interval = "10s"
          timeout  = "2s"
        }
      }
      meta {
        index = "${index}"
        clusterId = "${cluster-id}"
        namesvcName = "${namesvc-name}|any"
        brokersvcName = "${brokersvc-name}|any"
      }
      artifact {
        source = "${broker-config}"
        destination = "local/conf"
      }
      template {
        source = "local/conf/broker.conf.tpl"
        destination = "local/conf/broker.conf"
        change_mode = "noop"
      }
    }
    ${task-namesvr-sidecar0}
    ${task-namesvr-sidecar1}
    ${task-namesvr-sidecar2}
  }
}