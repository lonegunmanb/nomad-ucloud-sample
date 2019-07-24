job "console-${cluster-id}" {
  datacenters = ["${az}"]
//  constraint {
//    attribute = "$${meta.az}"
//    value = "${az}"
//  }
  group "console" {
    task "console" {
      driver = "docker"
      config {
        image = "${console-image}"
        network_mode = "host"
      }
      template {
        data = <<EOH
          JAVA_OPTS="-Drocketmq.namesrv.addr=localhost:{{env "NOMAD_PORT_namesvc${cluster-id}_namesvr0"}};localhost:{{env "NOMAD_PORT_namesvc${cluster-id}_namesvr1"}};localhost:{{env "NOMAD_PORT_namesvc${cluster-id}_namesvr2"}} -Dcom.rocketmq.sendMessageWithVIPChannel=false -Dserver.port={{env "NOMAD_PORT_tcp"}}"
          EOH

        destination = "local/file.env"
        env = true
      }
      resources {
        cpu = 500
        memory = 2048
        network {
          port "tcp" {}
        }
      }
      service {
        name = "console${cluster-id}"
        port = "tcp"
        check {
          type     = "tcp"
          port     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
    task "namesvc${cluster-id}" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "namesvc-sidecar-${cluster-id}-0",
          "-upstream", "namesvc-${cluster-id}-0:$${NOMAD_PORT_namesvr0}",
          "-service", "namesvc-sidecar-${cluster-id}-1",
          "-upstream", "namesvc-${cluster-id}-1:$${NOMAD_PORT_namesvr1}",
          "-service", "namesvc-sidecar-${cluster-id}-2",
          "-upstream", "namesvc-${cluster-id}-2:$${NOMAD_PORT_namesvr2}",
        ]
      }
      resources {
        network {
          port "namesvr0" {}
          port "namesvr1" {}
          port "namesvr2" {}
        }
      }
    }
  }
}