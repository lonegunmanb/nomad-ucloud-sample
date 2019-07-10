task "dledger${index}" {
  driver = "exec"
  config {
    command = "consul"
    args    = [
      "connect", "proxy",
      "-service", "dleddger-sidecar${index}",
      "-upstream", "dledger-${cluster-id}-${index}:$${NOMAD_PORT_tcp}",
    ]
  }
  resources {
    network {
      port "tcp" {}
    }
  }
}