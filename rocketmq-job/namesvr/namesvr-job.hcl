job "${job-name}" {
  datacenters = ["cn-bj2"]
  affinity {
    attribute = "$${meta.az}"
    value     = "${az}"
    weight    = 100
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
        network {
          port "tcp" {}
        }
      }
    }

    task "connect-proxy" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "namesvr-${cluster-id}-${index}",
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