job "${job-name}" {
  datacenters = ["cn-bj2"]
  constraint {
    attribute = "$${meta.az}"
    value     = "${az}"
  }
  group "namesvr" {
    task "namesvr" {
      driver = "docker"
      config {
        image = "${namesvr-image}"
        port_map = {
          tcp = 9876
        }
        command = "${cmd}"
        args = []
      }
      resources {
        cpu = 1000
        memory = 4096
        network {
          port "tcp" {}
        }
      }
      service {
        name = "${namesvc-name}"
        port = "tcp"
        check {
          type     = "tcp"
          port     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    task "connect-proxy" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "namesvc-${cluster-id}-${index}",
          "-service-addr", "$${NOMAD_ADDR_namesvr_tcp}",
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
  }
}