job "JOBNAME" {
  datacenters = ["cn-bj2"]

  group "redis" {
    task "server" {
      driver = "docker"
      config {
        image = "uhub.service.ucloud.cn/lonegunmanb/redis:latest"
        port_map = {
          tcp = 6379
        }
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
          "-service", "redis",
          "-service-addr", "${NOMAD_ADDR_server_tcp}",
          "-listen", ":${NOMAD_PORT_tcp}",
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

  group "web" {
    task "web" {
      driver = "docker"

      config {
        image = "uhub.service.ucloud.cn/lonegunmanb/redis:5.0.5-alpine"
        command = "tail"
        args = ["-f", "/dev/null"]
        network_mode = "host"
      }
      env {
        REDIS_PORT = "${NOMAD_PORT_proxy_tcp}"
      }
    }

    task "proxy" {
      driver = "exec"

      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "web",
          "-upstream", "redis:${NOMAD_PORT_tcp}",
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