job "${job-name}" {
  datacenters = ["cn-bj2"]
  constraint {
    attribute = "$${meta.az}"
    value     = "${az}"
  }
  group "broker" {
    task "console" {
      driver = "docker"
      config {
        image = "${console-image}"
        port_map = {
          tcp = 8080
        }
      }
      template {
        data = <<EOH
          JAVA_OPTS="-Drocketmq.namesrv.addr={{range $index, $service := service "${namesvc-name}|any"}}{{if ne $index 0}};{{end}}{{$service.Address}}:{{$service.Port}}{{end}} -Dcom.rocketmq.sendMessageWithVIPChannel=false"
          EOH

        destination = "local/file.env"
        env         = true
      }
      resources {
        cpu = 1000
        memory = 4096
        network {
          port "tcp" {}
        }
      }
    }
    task "broker" {
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
  }
}