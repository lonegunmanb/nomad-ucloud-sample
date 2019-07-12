job "console-${cluster-id}" {
  datacenters = ["cn-bj2"]
  constraint {
    attribute = "$${meta.az}"
    value     = "${az}"
  }
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
      env = true
      change_mode = "restart"
    }
    resources {
      cpu = 1000
      memory = 4096
      network {
        port "tcp" {}
      }
    }
  }
}