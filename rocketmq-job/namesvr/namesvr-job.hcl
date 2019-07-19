job "${job-name}" {
  datacenters = ["${az}"]
  constraint {
    attribute = "$${node.class}"
    value     = "${node-class}"
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
        memory = 2048
        network {
          port "tcp" {}
        }
      }
      service {
        name = "nameServer${cluster-id}"
        port = "tcp"
        check {
          type = "tcp"
          port = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }
    }

    task "connect-proxy-${index}" {
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