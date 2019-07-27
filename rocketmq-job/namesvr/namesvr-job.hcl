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
  group "namesvr" {
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

    task "connect-proxy" {
      driver = "exec"
      config {
        command = "consul"
        args = [
          "connect",
          "proxy",
          "-service",
          "namesvc-${cluster-id}-$${NOMAD_ALLOC_INDEX}",
          "-service-addr",
          "$${NOMAD_ADDR_namesvr_tcp}",
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
  }
}