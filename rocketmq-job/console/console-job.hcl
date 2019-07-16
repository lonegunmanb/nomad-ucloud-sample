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
          JAVA_OPTS="-Drocketmq.namesrv.addr=localhost:{{env "NOMAD_PORT_namesvc${cluster-id}0_tcp"}};localhost:{{env "NOMAD_PORT_namesvc${cluster-id}1_tcp"}};localhost:{{env "NOMAD_PORT_namesvc${cluster-id}2_tcp"}} -Dcom.rocketmq.sendMessageWithVIPChannel=false"
          EOH

        destination = "local/file.env"
        env = true
      }
      resources {
        cpu = 1000
        memory = 4096
        network {
          port "tcp" {
            static = "8080"
          }
        }
      }
    }
    ${task-namesvr-sidecar0}
    ${task-namesvr-sidecar1}
    ${task-namesvr-sidecar2}
  }
}