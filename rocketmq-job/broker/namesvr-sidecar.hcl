task "namesvr${index}" {
  driver = "exec"
  config {
    command = "consul"
    args    = [
      "connect", "proxy",
      "-service", "namesvr-sidecar${index}",
      "-upstream", "namesvr-${cluster-id}-${index}:$${NOMAD_PORT_tcp}",
    ]
  }
  resources {
    network {
      port "tcp" {}
    }
  }
}